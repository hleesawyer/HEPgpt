%%nim
import std/strformat
import std/httpclient
import strutils
import std/os
import std/random

# import std/rdstdin

# TODO
# - process the html
# - get all the data


### FOR ASYNC REQUESTS USE ###
# Async is used when program speed is I/O bound rather than cpu bound
# import std/[asyncdispatch, httpclient]

# proc asyncProc(): Future[string] {.async.} =
#   var client = newAsyncHttpClient()
#   return await client.getContent("http://example.com")

# echo waitFor asyncProc()

##############################

proc return_request*(url: string, idx: int) = 
    # How to add documentation to proc?
    
    # runnableExamples:
        # my_request = "http://export.arxiv.org/api/query?search_query=all:electron&start=0&max_results=10"
        # echo return_request(my_request)

    var 
        client = newHttpClient()
        # Add the request here in this line
        d = client.request(url)
        data = d.body()

    writeFile(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{url.replace('/','.')}_unparsed_{idx}.txt",data)



if isMainModule:

    # Define consts and vars.
    # 20,000 and 10,000 means the requests will randomly vary in milliseconds between at least 20s and 20+10=30s
    const minRandDelayInMilliseconds = 20000
    const additionalDelayInMilliseconds = 10000
    var urlList: seq[string]

    # For debugging.
    var randDelay: int

    # Process the urlList from urlFile.txt
    try:
        for line in lines "/home/wrkn/GitRepos/HEPgpt/data-gathering/urlFile.txt":
            urlList.add(line)
    except Exception:
        echo getCurrentExceptionMsg()

    # Put some space between the compiler line and first output line.
    echo ""

    # Loop through the urls and return the request in files based on the id of the url.
    # Also, implement a random request delay timer so we wait a minimum and max number of milliseconds between requests according to the robots.txt file (cern.astlas=20000ms min)
    for idx, url in urlList:
        
        try:
            return_request(url, idx)
            echo &"Request {idx} completed.\n"
        except:
            echo "Request failed with error:"
            echo getCurrentExceptionMsg()
        
        # Do not execute sleep on the final iteration.
        if idx != len(urlList)-1:
            # For debugging.
            randDelay = rand(additionalDelayInMilliseconds) + minRandDelayInMilliseconds
            echo &"randDelay={randDelay}ms"
            os.sleep(randDelay)

            # Non debugging.
            # os.sleep(rand(additionalDelayInMilliseconds) + minRandDelayInMilliseconds)

    echo "All procesing complete."