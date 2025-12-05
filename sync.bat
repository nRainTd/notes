@echo off
start "realtimesync" "D:\Applications\FreeFileSync\RealTimeSync.exe" ./content/BatchRun.ffs_batch
npx quartz sync --no-pull