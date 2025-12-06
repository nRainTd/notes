---
创建: 2025-11-07
tags:
  - CTF/比赛/25/强网杯初赛/Web
---

# SecretVault  ^toc

- [[#SecretVault  ^toc|SecretVault]]
	- [[#1 概览|1 概览]]
		- [[#1.1 描述|1.1 描述]]
		- [[#1.2 架构|1.2 架构]]
		- [[#1.3 功能|1.3 功能]]
	- [[#2 源码概况|2 源码概况]]
		- [[#2.1 源码|2.1 源码]]
			- [[#2.1.1 `main.go`|2.1.1 `main.go`]]
		- [[#2.2 `app.py`|2.2 `app.py`]]
		- [[#2.3 概况|2.3 概况]]
			- [[#2.3.1 代理和 Jwt 鉴权|2.3.1 代理和 Jwt 鉴权]]
			- [[#2.3.2 密码仓库|2.3.2 密码仓库]]
	- [[#3 解题|3 解题]]
		- [[#3.1 `X-User` 缺省值|3.1 `X-User` 缺省值]]
		- [[#3.2 `Connection: X-User` 删掉 `X-User`|3.2 `Connection: X-User` 删掉 `X-User`]]
		- [[#3.3 `Connection` 研究|3.3 `Connection` 研究]]
			- [[#3.3.1 规范|3.3.1 规范]]
			- [[#3.3.2 实现|3.3.2 实现]]

## 1 概览

### 1.1 描述

> [!info] 题目描述
> 小明最近注册了很多网络平台账号，为了让账号使用不同的强密码，小明自己动手实现了一套非常“安全”的密码存储系统 – SecretVault，但是健忘的小明没记住主密码，你能帮他找找吗

### 1.2 架构

本题给的附件里直接给了 `Dockerfile` 和 `entrypoint.sh` 容器初始化脚本；如下面两张图所示。

![[25强网杯初赛复现-251107-220755.png]]

![[25强网杯初赛复现-251107-221003.png]]

然后，从上两张图左边的目录结构也可以看出，本题的容器环境中会运行两个服务：
+ 一个是 `go` 写的，负责代理和处理 `jwt` 相关逻辑；
+ 另一个是 `python` 写的，负责作为 `web` 后端，实现密码仓库的相关功能。

### 1.3 功能

如下图所示，直接访问是一个登录框；我们没有账号密码，也可以看到注册按钮

![[25强网杯初赛复现-251107-221759.png]]

我们注册一个账号，注册完成后登录。

![[25强网杯初赛复现-251107-221859.png]]

如下图，登录后是一个可以查看和保存密码的界面；在左边编辑好密码信息后，点击 `save`，右边就会新增一行。

![[25强网杯初赛复现-251107-222034.png]]

以上就是这个系统的全部功能。

根据题目要求，小明忘记了主密码；那么我们的任务就是想办法至少用小明的账号登录进系统，`flag` 应该就存在里面。

## 2 源码概况

### 2.1 源码

下面是两个服务的源码：

#### 2.1.1 `main.go`

```go
//main.go

package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/mux"
)

var (
	SecretKey = hex.EncodeToString(RandomBytes(32))
)

type AuthClaims struct {
	jwt.RegisteredClaims
	UID string `json:"uid"`
}

func RandomBytes(length int) []byte {
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		return nil
	}
	return b
}

func SignToken(uid string) (string, error) {
	t := jwt.NewWithClaims(jwt.SigningMethodHS256, AuthClaims{
		UID: uid,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    "Authorizer",
			Subject:   uid,
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
		},
	})
	tokenString, err := t.SignedString([]byte(SecretKey))
	if err != nil {
		return "", err
	}
	return tokenString, nil
}

func GetUIDFromRequest(r *http.Request) string {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		cookie, err := r.Cookie("token")
		if err == nil {
			authHeader = "Bearer " + cookie.Value
		} else {
			return ""
		}
	}
	if len(authHeader) <= 7 || !strings.HasPrefix(authHeader, "Bearer ") {
		return ""
	}
	tokenString := strings.TrimSpace(authHeader[7:])
	if tokenString == "" {
		return ""
	}
	token, err := jwt.ParseWithClaims(tokenString, &AuthClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(SecretKey), nil
	})
	if err != nil {
		log.Printf("failed to parse token: %v", err)
		return ""
	}
	claims, ok := token.Claims.(*AuthClaims)
	if !ok || !token.Valid {
		log.Printf("invalid token claims")
		return ""
	}
	return claims.UID
}

func main() {
	authorizer := &httputil.ReverseProxy{
		Director: func(req *http.Request) {
			req.URL.Scheme = "http"
			req.URL.Host = "127.0.0.1:5000"

			uid := GetUIDFromRequest(req)
			log.Printf("Request UID: %s, URL: %s", uid, req.URL.String())
			req.Header.Del("Authorization")
			req.Header.Del("X-User")
			req.Header.Del("X-Forwarded-For")
			req.Header.Del("Cookie")

			if uid == "" {
				req.Header.Set("X-User", "anonymous")
			} else {
				req.Header.Set("X-User", uid)
			}
		},
	}

	signRouter := mux.NewRouter()
	signRouter.HandleFunc("/sign", func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.RemoteAddr, "127.0.0.1:") {
			http.Error(w, "Forbidden", http.StatusForbidden)
		}
		uid := r.URL.Query().Get("uid")
		token, err := SignToken(uid)
		if err != nil {
			log.Printf("Failed to sign token: %v", err)
			http.Error(w, "Failed to generate token", http.StatusInternalServerError)
			return
		}
		w.Write([]byte(token))
	}).Methods("GET")

	log.Println("Sign service is running at 127.0.0.1:4444")
	go func() {
		if err := http.ListenAndServe("127.0.0.1:4444", signRouter); err != nil {
			log.Fatal(err)
		}
	}()

	log.Println("Authorizer middleware service is running at :5555")
	if err := http.ListenAndServe(":5555", authorizer); err != nil {
		log.Fatal(err)
	}
}
```

### 2.2 `app.py`

```python
# app.py

import base64
import os
import secrets
import sys
from datetime import datetime
from functools import wraps
import requests

from cryptography.fernet import Fernet
from flask import (
    Flask,
    flash,
    g,
    jsonify,
    make_response,
    redirect,
    render_template,
    request,
    url_for,
)
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.exc import IntegrityError
import hashlib

db = SQLAlchemy()

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    salt = db.Column(db.String(64), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    vault_entries = db.relationship('VaultEntry', backref='user', lazy=True, cascade='all, delete-orphan')


class VaultEntry(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    label = db.Column(db.String(120), nullable=False)
    login = db.Column(db.String(120), nullable=False)
    password_encrypted = db.Column(db.Text, nullable=False)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

def hash_password(password: str, salt: bytes) -> str:
    data = salt + password.encode('utf-8')
    for _ in range(50):
        data = hashlib.sha256(data).digest()
    return base64.b64encode(data).decode('utf-8')

def verify_password(password: str, salt_b64: str, digest: str) -> bool:
    salt = base64.b64decode(salt_b64.encode('utf-8'))
    return hash_password(password, salt) == digest

def generate_salt() -> bytes:
    return secrets.token_bytes(16)

def create_app() -> Flask:
    app = Flask(__name__)
    app.config['SECRET_KEY'] = secrets.token_hex(32)
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'sqlite:///vault.db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SIGN_SERVER'] = os.getenv('SIGN_SERVER', 'http://127.0.0.1:4444/sign')
    fernet_key = os.getenv('FERNET_KEY')
    if not fernet_key:
        raise RuntimeError('Missing FERNET_KEY environment variable. Generate one with `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`.')
    app.config['FERNET_KEY'] = fernet_key
    db.init_app(app)

    fernet = Fernet(app.config['FERNET_KEY'])
    with app.app_context():
        db.create_all()

        if not User.query.first():
            salt = secrets.token_bytes(16)
            password = secrets.token_bytes(32).hex()
            password_hash = hash_password(password, salt)
            user = User(
                id=0,
                username='admin',
                password_hash=password_hash,
                salt=base64.b64encode(salt).decode('utf-8'),
            )
            db.session.add(user)
            db.session.commit()

            flag = open('/flag').read().strip()
            flagEntry = VaultEntry(
                user_id=user.id,
                label='flag',
                login='flag',
                password_encrypted=fernet.encrypt(flag.encode('utf-8')).decode('utf-8'),
                notes='This is the flag entry.',
            )
            db.session.add(flagEntry)
            db.session.commit()

    def login_required(view_func):
        @wraps(view_func)
        def wrapped(*args, **kwargs):
            uid = request.headers.get('X-User', '0')
            print(uid)
            if uid == 'anonymous':
                flash('Please sign in first.', 'warning')
                return redirect(url_for('login'))
            try:
                uid_int = int(uid)
            except (TypeError, ValueError):
                flash('Invalid session. Please sign in again.', 'warning')
                return redirect(url_for('login'))
            user = User.query.filter_by(id=uid_int).first()
            if not user:
                flash('User not found. Please sign in again.', 'warning')
                return redirect(url_for('login'))

            g.current_user = user
            return view_func(*args, **kwargs)

        return wrapped

    @app.route('/')
    def index():
        uid = request.headers.get('X-User', '0')
        if not uid or uid == 'anonymous':
            return redirect(url_for('login'))
        
        return redirect(url_for('dashboard'))

    @app.route('/register', methods=['GET', 'POST'])
    def register():
        if request.method == 'POST':
            username = request.form.get('username', '').strip()
            password = request.form.get('password', '')
            confirm_password = request.form.get('confirm_password', '')
            if not username or not password:
                flash('Username and password are required.', 'danger')
                return render_template('register.html')
            if password != confirm_password:
                flash('Passwords do not match.', 'danger')
                return render_template('register.html')
            salt = generate_salt()
            password_hash = hash_password(password, salt)
            user = User(
                username=username,
                password_hash=password_hash,
                salt=base64.b64encode(salt).decode('utf-8'),
            )
            db.session.add(user)
            try:
                db.session.commit()
            except IntegrityError:
                db.session.rollback()
                flash('Username already exists. Please choose another.', 'warning')
                return render_template('register.html')
            flash('Registration successful. Please sign in.', 'success')
            return redirect(url_for('login'))
        return render_template('register.html')

    @app.route('/login', methods=['GET', 'POST'])
    def login():
        if request.method == 'POST':
            username = request.form.get('username', '').strip()
            password = request.form.get('password', '')
            user = User.query.filter_by(username=username).first()
            if not user or not verify_password(password, user.salt, user.password_hash):
                flash('Invalid username or password.', 'danger')
                return render_template('login.html')
            r = requests.get(app.config['SIGN_SERVER'], params={'uid': user.id}, timeout=5)
            if r.status_code != 200:
                flash('Unable to reach the authentication server. Please try again later.', 'danger')
                return render_template('login.html')
            
            token = r.text.strip()
            response = make_response(redirect(url_for('dashboard')))
            response.set_cookie(
                'token',
                token,
                httponly=True,
                secure=app.config.get('SESSION_COOKIE_SECURE', False),
                samesite='Lax',
                max_age=12 * 3600,
            )
            return response
        return render_template('login.html')

    @app.route('/logout')
    def logout():
        response = make_response(redirect(url_for('login')))
        response.delete_cookie('token')
        flash('Signed out.', 'info')
        return response

    @app.route('/dashboard')
    @login_required
    def dashboard():
        user = g.current_user
        entries = [
            {
                'id': entry.id,
                'label': entry.label,
                'login': entry.login,
                'password': fernet.decrypt(entry.password_encrypted.encode('utf-8')).decode('utf-8'),
                'notes': entry.notes,
                'created_at': entry.created_at,
            }
            for entry in user.vault_entries
        ]
        return render_template('dashboard.html', username=user.username, entries=entries)

    @app.route('/passwords/new', methods=['POST'])
    @login_required
    def create_password():
        user = g.current_user
        label = request.form.get('label', '').strip()
        login_value = request.form.get('login', '').strip()
        password_plain = request.form.get('password', '').strip()
        notes = request.form.get('notes', '').strip() or None
        if not label or not login_value or not password_plain:
            flash('Service name, login, and password are required.', 'danger')
            return redirect(url_for('dashboard'))
        encrypted_password = fernet.encrypt(password_plain.encode('utf-8')).decode('utf-8')
        entry = VaultEntry(
            user_id=user.id,
            label=label,
            login=login_value,
            password_encrypted=encrypted_password,
            notes=notes,
        )
        db.session.add(entry)
        db.session.commit()
        flash('Password entry saved.', 'success')
        return redirect(url_for('dashboard'))

    @app.route('/passwords/<int:entry_id>', methods=['DELETE'])
    @login_required
    def delete_password(entry_id: int):
        user = g.current_user
        entry = VaultEntry.query.filter_by(id=entry_id, user_id=user.id).first()
        if not entry:
            return jsonify({'success': False, 'message': 'Entry not found'}), 404
        db.session.delete(entry)
        db.session.commit()
        return jsonify({'success': True})

    return app


if __name__ == '__main__':
    flask_app = create_app()
    flask_app.run(host='127.0.0.1', port=5000, debug=False)
```

### 2.3 概况

#### 2.3.1 代理和 Jwt 鉴权

`go` 语言写的代理服务器中，有一个开在 `5555` 端口的 `httpReserveProxy`，它接受来自前端的请求，会删除一些头部，验证 `jwt` 并提取出 `uid` 存入 `X-User` 头部；

除此之外，还有一个开在 `4444` 端口的 `jwt` 签名服务，主要是接受本地请求传来的 `uid`，把它签名成 `token` 返回给请求者。

#### 2.3.2 密码仓库

`py` 写的 `Web` 服务器中，首先会初始化一个数据库，用于存储用户信息和用户的密码仓库，`admin` 用户会初始化为 `id` 为 `0` 的用户，有一个随机生成的密码，数据库中的密码是加盐哈希存储的；并且 `admin` 用户也初始化了一个密码记录，`flag` 就保存在这，因此我们只需登录 `admin` 用户就能拿到 `flag`。

`/regisiter` 路由就是把用户名和加盐密码以及盐保存到数据库中，没啥好说。

`/login` 路由，用数据库验证完用户名密码后，会拿到此用户的 `id`，发到 `4444` 端口签名为 `jwt` 后保存到 `cookie` 中。

后面三个路由，都有一个中间件 `login_require`，它会从 `X-User` 头部中取出 `id`，如果没有 `X-User` 就设为默认值 `0`；然后用这个 `id` 从数据库中读取该用户信息的数据库对象，然后保存在 `g.current_user` 中供本次请求使用。

`/dashboard` 路由，从 `g.current_user` 中保存的数据库对象中提取出信息作为数据渲染模板；然后返回模板页面。

`/passwords/new` 路由的作用是把一个密码记录保存到数据库。

`/passwords/<int:entry_id>` 路由的作用是从数据库中删除对应的密码记录。

## 3 解题

### 3.1 `X-User` 缺省值

解题的关键就在 `/dashboard` 路由前面的 `login_require` 中间件获取已登录用户的 `uid` 的逻辑上 (如下图所示)；
这里的逻辑是代理服务器验证 `jwt` 成功后把 `X-User` 头部设为正确的 `uid`，然后 `python` 这边读取它，如果没读到就用默认值 `0` 作为 `uid`；
获取到 `uid` 后，通过 `uid` 从数据库中读出对应用户信息的数据库对象并保存到 `g.current_user` 中供本次请求使用。

![[25强网杯初赛复现-251107-230143.png]]

然后我们从前面的源码概况分析又知道，`0` 是 `admin` 的 `uid`；
也就是说，只要我们使到达 `python` 的请求报文中没有头部 `X-User`，那么就能使 `uid` 为零，然后就能在 `/dashboard` 页面直接看到 `admin` 保存的 `password`，即 `flag`。

那么能不能实现呢？这得分析一下 `go` 那边的代理服务器。

我们看下面这段代码，首先调用 `GetUIDFromRequest(req)` 从 `jwt` 中验证并提取出 `uid`；然后调用 `req.Header.Del` 删除四个头部，最后如果前面获取的 `uid` 为空，就把 `X-User` 设为 `anonymous`；如果不为空，就设为相应的值。
总之这一步就限定了最后传递给 `python` 的请求包中不可能没有 `X-User`。

![[Web_SecretVault-251107-234036.png]]

`GetUIDFromRequest` 里面是单纯的从 `jwt` 中取出 `uid` 的逻辑，也没有可以绕过的点；如果 `jwt` 不对，就不可能从中取出 `uid` 为 `0`。

### 3.2 `Connection: X-User` 删掉 `X-User`

现在，摆在我们面前的只有一个问题，就是怎么让代理发往 `Web` 服务器的请求包中没有 `X-User` 头部？

这里我们可以用 `Connection` 头部，对于出现在这个头部中的 `connection-option`，代理会删掉其同名的 `Header`； #知识/Http/Connection 

利用这个特性，我们只需要访问 `/dashboard` 路由时加上 `Connection: X-User`，就能使得从代理发往 `python` 的请求包中 `X-User` 头部被删去，然后就会用缺省值 `0` 作为 `uid`，然后就能成功登录 `admin` 账户，获取到 `flag`。

最终就能按下图所示那样拿到 `flag`。

![[Web_SecretVault-251108-142316.png]]

### 3.3 `Connection` 研究

#### 3.3.1 规范

但是，为什么呢？这背后的机制时什么？`Connection` 原本的语义又是什么呢？

这需要我们去研究原理，而不是止步于漏洞利用。

于是让我们去翻一下 HTTP1.1 的规范

> [!cite] [RFC_7230_Connection](https://www.rfc-editor.org/rfc/rfc7230#section-6.1)
> 在 HTTP1.1 的 RFC 规范中，关于 `Connection` 头部的部分，有这么一段话：
> 
> When a header field aside from Connection is used to supply control information for or about the current connection, the sender MUST list the corresponding field-name within the Connection header field.  
> A proxy or gateway MUST parse a received Connection header field before a message is forwarded and, for each connection-option in this field, remove any header field(s) from the message with the same name as the connection-option, and then remove the Connection header field itself (or replace it with the intermediary's own connection options for the forwarded message).

我自己翻译一下，大概意思就是：

当一个头部中存储的信息是用来控制当前连接的，即 `hop_by_hop` 逐跳的；那么这个头部名需要在 `Connection` 中列出来。

一个代理或者网关必须在转发消息前解析 `Connection` 头部，并且对于其中的每一个 `connection-option`，需要**移除**和 `connection-option` 同名的头部，最后移除 `Connection` 头部本身 (或者用代理或网关自己生成的新 `Connection` 代替原来的头部)。

#### 3.3.2 实现

上面只是规范中规定了这一点，那么 `go` `http` 反向代理的源码中是否实现了规范呢？这还需要我们去审计一下源码。

我们自己对请求的手动处理是依赖给 `ReverseProxy` 结构体的 `Director` 属性赋为我们的自定义函数实现的，当请求到来时，会调用 `Director` 函数对请求进行自定义处理。

![[Web_SecretVault-251108-144547.png]]

但是，并不是只有 `Director` 这个函数会修改请求包，因为这个只是给我们提供修改请求能力的“api”；事实上，执行完我们自定义的 `Director` 函数后，`Go` 依然会执行其内部逻辑去修改请求包；

`Director` 属性的注释里也明确说了，执行完 `Director` 之后，反向代理也会去删掉 `hop-by-hop` 头部；从注释层面验证了 `go` 确实是遵循规范的。

![[Web_SecretVault-251108-145207.png]]

为了进一步验证，我们找到调用 `Director` 附近的源码，如下图所示：`A` 处的 `Director` 被调用后，确实紧接着调用了 `B` 处的 `removeHopByHopHeaders`。

![[Web_SecretVault-251108-145513.png]]

我们跟进 `removeHopByHopHeaders` 函数内看看，确实是删除 `Connection` 中 `connection-option` 同名头部的逻辑。

![[Web_SecretVault-251108-145534.png]]

到此，探究结束！
