import std/strformat
import std/httpclient
import std/htmlparser
import std/xmltree
import strutils
import sequtils
import std/os
import std/random

# import std/rdstdin


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
    # for num_processed, url in newUrlsList:

        # If its thefirst line, add the url
        # if num_processed == 0:
            # new_urls_string.add(url)
            # If the first line is also the last line, dont add a newline
            # if num_processed != len(newUrlsList)-1:
                # new_urls_string.add("\n")
        # If instead, the current url is the last url, add the url but not a new line
        # elif num_processed == len(newUrlsList)-1:
            # new_urls_string.add(url)
        # It isn't the first or last line, add a new line, then add the url
        # else:
            # new_urls_string.add("\n")
            # new_urls_string.add(url)
            
    return newUrlsList
    # return new_urls_string
    


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

    # Write the parsed data to file
    # writeFile(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{request_url.replace('/','.')}_unparsed_{idx}.txt",data)

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


# proc config_


if isMainModule:

    # Define consts and vars.
    # 20,000 and 10,000 means the requests will randomly vary in milliseconds between at least 20s and 20+10=30s
    const 
        minRandDelayInMilliseconds = 5000
        additionalDelayInMilliseconds = 10000
    
    # For debugging.
    var randDelay: int
    
    # Put some space between the compiler line and first output line.
    echo ""
    
    # Initialize the first urlList
     echo "initializing urlList:"
    var 
        urlList = initialize_url_list()    
        urls_remaining_it = len(urlList)
        num_urls_to_add = 0
        num_processed = 0


    # Loop through the urls and return the request in files based on the id of the url.
    # Also, implement a random request delay timer so we wait a minimum and max number of milliseconds between requests according to the robots.txt file (cern.astlas=20000ms min)
    while urls_remaining_it > 0:
        # Convert the ints to string
        echo "urls_remaining_it:" &  $urls_remaining_it
        echo "num_processed:" & $num_processed

        # For each url we process, Initialize or re-Initialize the urlList
        echo "initializing urlList:"
        urlList = initialize_url_list()    

        for id_urlListInit, url in urlList:
            echo "url in for loop:" & url
            echo "id_urlListInit in for loop:" & $id_urlListInit
            

            # If the current url in the loop idx has not been seen in num_processed url iterations in the urllist(the last one we did)
            # then process the url.
            if num_processed >= id_urlListInit:
                try:
                    echo "MAKING REQUEST..."
                    var
                        data = return_request(url, id_urlListInit)
                        parsed_data = parse_request(data)
                    echo "REQUEST COMPLETE."
                    try:
                        # How many urls have we found that need to be added to the file?
                        echo "record_urls"
                        num_urls_to_add = record_urls(parsed_data)
                        echo "recorded"
                        # Add that number of iterations to our main loop
                        urls_remaining_it += num_urls_to_add
                        echo "urls_remaining_it updated:" & $urls_remaining_it
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
            # One url is processed, update urls_remaining_it
            
            urls_remaining_it -= 1
            echo "urls_remaining_it: reduced:" & $urls_remaining_it
            # At the same time, update the number of urls we have processed so we know where to skip in urlList
            num_processed += 1
            echo "num_processed updated:" & $num_processed
            
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

    # TODO:
        # 1. process forward and backlinks. If the url exists, then it shouldn't be readded to the list. only process once
        # it could lead to duplicate entries
        # 2. add real html parsing
        # 3. slow down the loop iterator and make sure it is doing what i think its doing
        # 4. try to get absolute url paths added so I can make sure the urls like /domains are not duplicates
        # 5. implement a way to monitor/keep the crawler on a specific domain and not wander around the internet
        # 6. look for and process robots.txt so when it moves around it doesn't cause a international incident
        # 7. 