import std/strformat
import std/httpclient
import std/htmlparser
import std/xmltree
import strutils
import sequtils
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

proc parse_request*(data: string): seq[string] = 

    # Initialize variables
    var 
        html = parseHtml(data)
        newUrlsList: seq[string] = @[]
        # new_urls_string = ""

    
    try:
        # Loop through the a tags found from the html document    
        for a in html.findAll("a"):
            newUrlsList.add(a.attr("href"))
    # If there are no a tags found, an exception occurs probably - test this
    except Exception:
        echo getCurrentExceptionMsg()

    # Loop through the list of urls found from the a tags in the html document
    # for idu, url in newUrlsList:

        # If its thefirst line, add the url
        # if idu == 0:
            # new_urls_string.add(url)
            # If the first line is also the last line, dont add a newline
            # if idu != len(newUrlsList)-1:
                # new_urls_string.add("\n")
        # If instead, the current url is the last url, add the url but not a new line
        # elif idu == len(newUrlsList)-1:
            # new_urls_string.add(url)
        # It isn't the first or last line, add a new line, then add the url
        # else:
            # new_urls_string.add("\n")
            # new_urls_string.add(url)
            
    return newUrlsList
    # return new_urls_string
    

  # return a #parsed_data

proc return_request*(request_url: string, idx: int): string = 
    # How to add documentation to proc?
    
    # runnableExamples:
        # my_request = "http://export.arxiv.org/api/query?search_query=all:electron&start=0&max_results=10"
        # echo return_request(my_request)

    var 
        client = newHttpClient()
        # Add the request here in this line
        d = client.request(request_url)
        data = d.body()

    writeFile(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{request_url.replace('/','.')}_unparsed_{idx}.txt",data)

    return data


proc record_urls*(newUrlsList: seq): int =

    var num_urls_to_add = 0
    try:
        # If the file exists
        # let f = open(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{request_url.replace('/','.')}_unparsed_{idx}.txt", fmAppend)
        
        let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmAppend)
        defer: f.close()

        # Loop through the discovered urls and record them in the urlFile
        for url in newUrlsList:
            f.write("\n" & url)
            num_urls_to_add += 1

    except Exception:
        let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
        defer: f.close()

        # Loop through the discovered urls and record them in the urlFile
        for url in newUrlsList:
            f.write("\n" & url)    
            num_urls_to_add += 1

    return num_urls_to_add


proc initialize_url_list*(): seq[string]= 

    var urlList: seq[string]

    # Construct urlList from urlFile.txt
    try:
        for line in lines "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt":
            urlList.add(line)
    except Exception:
        echo getCurrentExceptionMsg()

    return urlList


if isMainModule:

    # Define consts and vars.
    # 20,000 and 10,000 means the requests will randomly vary in milliseconds between at least 20s and 20+10=30s
    const minRandDelayInMilliseconds = 5000
    const additionalDelayInMilliseconds = 10000
    
    # For debugging.
    var randDelay: int

    # Put some space between the compiler line and first output line.
    echo ""

    # Initialize the first urlList
    echo "initializing urlList:"
    var urlList = initialize_url_list()    

    # Loop through the urls and return the request in files based on the id of the url.
    # Also, implement a random request delay timer so we wait a minimum and max number of milliseconds between requests according to the robots.txt file (cern.astlas=20000ms min)
    var 
        url_iter = len(urlList)
        num_urls_to_add = 0
        idu = 0

    while url_iter > 0:
        # Convert the ints to string
        echo "url_iter:" &  $url_iter
        echo "idu:" & $idu

        # For each url we process, Initialize or re-Initialize the urlList
        echo "initializing urlList:"
        urlList = initialize_url_list()    

        for idx, url in urlList:
            echo "url in for loop:" & url
            echo "idx in for loop:" & $idx
            

            # If the current url in the loop matches the idu-th url we have iterated through in the list(the last one we did)
            if idu == idx:
                try:
                    echo "MAKING REQUEST..."
                    var
                        data = return_request(url, idx)
                        parsed_data = parse_request(data)
                    echo "REQUEST COMPLETE."
                    try:
                        # How many urls have we found that need to be added to the file?
                        echo "record_urls"
                        num_urls_to_add = record_urls(parsed_data)
                        echo "recorded"
                        # Add that number of iterations to our main loop
                        url_iter += num_urls_to_add
                        echo "url_iter updated:" & $url_iter
                    except Exception:
                        echo "failed to record_urls"
                        echo getCurrentExceptionMsg()
                except:
                    echo "Request failed with error:"
                    echo getCurrentExceptionMsg()

            # try:
                # Try to record the parsed data
                # writeFile(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{url.replace('/','.')}_parsed_{idx}.txt",parsed_data)
            # except Exception:
                # echo "failed to record parsed_data"
                # echo getCurrentExceptionMsg()

            echo &"Request {idx} completed.\n"
            # One url is processed, update url_iter
            
            url_iter -= 1
            echo "url_iter: reduced:" & $url_iter
            # At the same time, update the number of urls we have processed so we know where to skip in urlList
            idu += 1
            echo "idu updated:" & $idu
            
            # Do not execute sleep on the final iteration.
            echo "setting delay"
            if idx != len(urlList)-1:
                # For debugging.
                randDelay = rand(additionalDelayInMilliseconds) + minRandDelayInMilliseconds
                echo &"randDelay={randDelay}ms"
                os.sleep(randDelay)

                # Non debugging.
                # os.sleep(rand(additionalDelayInMilliseconds) + minRandDelayInMilliseconds)

    echo "All procesing complete."