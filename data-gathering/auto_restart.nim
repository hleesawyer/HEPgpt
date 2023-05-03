import std/osproc
import std/strutils



proc clean_TZ*() =

  var pid: string = ""
  var state: string = ""

  let (psOut, _) = execCmdEx("ps -eo pid,state")
  
  
  echo "Checking States..."
  for line in psOut.splitLines():
    if "PID" in line:
      continue

    # echo line
  
    var fields = line.split(' ')
    try:
      pid = fields[^2]
      state = fields[^1]
      # echo $pid & " " & $state
    except:
      discard
    
    if state == "T" or state == "Z":
      echo "pid/state:"
      echo $pid & " " & $state
      discard execCmd("kill -9 " & $pid)


  echo "Check complete - any T or Z state processes have been killed."



proc start_crawler*() = 
  
  var pid: string = ""
  var state: string = ""
  var cmd: string = ""
  
  let (psOut, _) = execCmdEx("ps -eo pid,state,cmd | grep atlas_crawler")
  let lines = psOut.splitLines()

  if len(lines) == 1:
    # The only line that exists is the command we just ran
    echo "only line"
    return
  
  echo "sc:Checking States..."
  for line in lines:
    if "PID" in line:
      continue

  
    var fields = line.split(' ')
    try:
      pid = fields[^3]
      state = fields[^2]
      cmd = fields[^1]
    except:
      discard

  # If atlas_crawler in cmd, and color notin cmd and it isn't running or sleeping...
  # then start the crawler
  if state != "R" and state != "S" and state != "D" and "color" notin cmd and "atlas_crawler" in cmd:
    # execCmd("nim c -r full/path/to/atlas_crawler.nim")
    discard execCmd("nim c -r ~/GitRepos/HEPgpt/data-gathering/atlas_crawler.nim")





if isMainModule:
  
  # First, clean the process tree from stopped or zombie processes
  clean_TZ()

  # Next, start the crawler if it isn't already running
  start_crawler()


  # For the chronjob, run the following...
  # run: "crontab -e" to open the crontab editor
  # make a line that says: "0 */6 * * * /path/to/conda/env/bin/python /path/to/script.py