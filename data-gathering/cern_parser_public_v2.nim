import std/strformat
import std/httpclient
import std/htmlparser
import std/xmltree
import strutils
import sequtils
import std/os
import std/random
import std/uri
import std/sets

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
        echo "FAILED 1"
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
    


proc return_request*(request_url: string, idx: int, to_process: var int): (string, int) = 
    # How to add documentation to proc?
    
    # runnableExamples:
        # my_request = "http://export.arxiv.org/api/query?search_query=all:electron&start=0&max_results=10"
        # echo return_request(my_request)
    var fixed_request = ""

    echo request_url
    if request_url == "\n":
        return ("", to_process)
    elif "\n" in request_url:
        echo "its in"
        fixed_request = request_url.replace("\n","")
        echo fixed_request
    elif request_url == "":
        return ("", to_process)
    
    else:
        fixed_request = request_url

    var client = newHttpClient()
        # Add the request here in this line
    echo "client created"
    var d = client.request(fixed_request)
    # var d = client.request(request_url)
    echo "requested"
    var data = d.body()
        # Get the urls from urlFile
    var lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
    lines = toSeq(toOrderedSet(lines))

    # Delete the line we just processed from urlList
    echo "delete lines"
    # echo lines
    lines.delete(idx)
    # echo lines
    echo "deleted"
    to_process = to_process - 1

    # Update urlList to reflect this change
    echo "updating urls"
    let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
    defer: f.close()

    let f_all = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlsAll.txt", fmAppend)
    defer: f_all.close()
    
    echo "writing lines"
    f.write("\n" & lines)

    echo "urlsAll.txt updated"
    f_all.write("\n" & fixed_request)

    return (data, to_process)


proc remove_url(to_process: var int, idu: int): int =
    var lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
    
    echo "delete lines"
    # echo lines
    lines.delete(idu)
    # echo lines
    echo "deleted"
    to_process = to_process - 1
    
    echo "updating urls"
    let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
    defer: f.close()
    echo "writing lines"
    
    f.write("\n" & lines)

    return to_process


proc record_urls_main*(f: File, newUrlsList: seq, leading_url_info: string, lines: seq, linesAll: seq, to_process: var int, num_urls_to_add: var int): (int, int) =

    # Loop through the discovered urls and record them in the urlFile
    for url in newUrlsList:
        # Don't add new urls 'url' if it already exists in urlFile.txt
        echo "leadingurlinfo:"
        echo leading_url_info
        echo "url:"
        echo url

        if leading_url_info & url & "\n" in lines:
            # http://www.iana.orghttp://pti.icann.org\n
            continue

        if leading_url_info & url & "/" & "\n" in lines:
            # http://www.iana.orghttp://pti.icann.org/\n
            continue

        if leading_url_info == url:
            ## http://www.iana.org == http://pti.icann.org
            continue

        if leading_url_info&"/" == url:
            # http://www.iana.org/
            continue

        try:
            # if $toSeq(url)[^1] == url:
                # http://www.iana.orghttp://pti.icann.org\n
                # continue
            if url & "/" in lines or $toSeq(url)[0..^2] in lines:
                continue
        except:
            discard
        
        if leading_url_info & url & "\n" in linesAll:
            # http://www.iana.orghttp://pti.icann.org\n
            continue

        if leading_url_info & url & "/" & "\n" in linesAll:
            # http://www.iana.orghttp://pti.icann.org/\n
            continue

        if url == "/":
            # If the entire new url is '/'
            # http://pti.icann.org
            continue
            
        # If leading_url_info not empty, if it isnt in the url, and if http not in the url
        if leading_url_info != "" and leading_url_info notin url and "http" notin url:
            # http://www.iana.org and http://www.iana.org notin http://pti.icann.org and http notin # http://pti.icann.org
            echo "adding2:"
            echo leading_url_info & url & "\n"

            try:
                if "/" != $toSeq(url)[0]:
                    f.write(leading_url_info & "/" & url & "\n")
                else:
                    f.write(leading_url_info & url & "\n")
            except:
                discard

            to_process += 1
        else:
            # http://pti.icann.org
            # https://www.iana.org != "", https://www.iana.org notin url, but http in url
            echo "regular url added2"

            f.write(url & "\n")
            
            to_process += 1

        num_urls_to_add += 1

    return (num_urls_to_add, to_process)


proc record_urls*(newUrlsList: seq, leading_url_info: string, to_process: var int): (int, int) =    

    var 
        num_urls_to_add = 0
        lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
        linesAll = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlsAll.txt".readFile().splitLines(keepEol = true)

    lines = toSeq(toOrderedSet(lines))
    linesAll = toSeq(toOrderedSet(lines))
    
    echo "LEADING URL INFO:"
    echo leading_url_info

    try:
        # If the file exists
        let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmAppend)
        (num_urls_to_add, to_process) = record_urls_main(f, newUrlsList, leading_url_info, lines, linesAll, to_process, num_urls_to_add)
        f.close()
    except Exception:
        # If it does not exist
        let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
        (num_urls_to_add, to_process) = record_urls_main(f, newUrlsList, leading_url_info, lines, linesAll, to_process, num_urls_to_add)
        f.close()


    return (num_urls_to_add, to_process)


proc remove_duplicate_urls*() =
    # Go back later and remove all the code that this little bit was intended to do
    
    var lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
    lines = toSeq(toOrderedSet(lines))

    let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
    defer: f.close()

    f.write(lines)


proc init_urls*(): seq[string]= 

    remove_duplicate_urls()

    var urls = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
    # echo urls
    return urls




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
    
    # Initialize the first urls
    echo "initializing urls:"
    var 
        urls = init_urls()
        tmp = urls
        to_process = len(urls)
        urls_remaining_it = len(urls)
        num_urls_to_add = 0
        data = ""
        newUrlList: seq[string] = @[]
        res: Uri
        leading_url_info: string
        lines: seq[string] = @[]
        urlFileSeq: seq[string] = @[]
    
    # echo urls

# MAIN LOOP #
    while to_process > 0:

        echo "test3"
        tmp = urls
        lines = init_urls() # Unecessary
        # echo lines

        for idu, url in tmp:

            # Try to get a new domain if one exists
            try:
                echo "parsing Uri"
                res = parseUri(url)
                echo "parsed Uri"
                leading_url_info = res.scheme & "://" & res.hostname
                if leading_url_info == "://":
                    leading_url_info = ""

                echo "leading url info set:"
                echo leading_url_info
            except:
                leading_url_info = ""
                echo "leading url info empty"

            echo "to_process:"
            echo to_process
            # Skip lines that have already been processed in urlsAll.txt
            echo "URL:"
            echo url
            # echo "LINES:"
            echo "idu:"
            echo idu

            # 4-20-23 : THE CURRENT PROBLEM IS THAT  "example.com" is in "example.com/domains"
            # BUT we still need to process "example.com/domains" and skip all instances of "example.com" exactly


            if url != "":
                echo "--------------------------------------------------URL notin lines!"
                (data, to_process) = return_request(url, idu, to_process)
                # urlsAll.txt is updated in return_request(), so update lines to reflext the update
                lines = init_urls()
                echo "lines redefined"
                echo lines
            else:
                echo "URL in lines!!!------------"
                echo "URL:"
                echo url
                if url=="\n":
                    echo "slashN"
                echo idu
                os.sleep(1000)
                to_process = remove_url(to_process, idu)
                continue

            echo to_process
            if data == "":
                continue

            echo "test4"
            newUrlList = parse_request(data)
            echo "test5"
            
            echo "to_process2:"
            echo to_process
            # (num_urls_to_add, to_process) = record_urls(newUrlList, tmp, leading_url_info, to_process)
            (num_urls_to_add, to_process) = record_urls(newUrlList, leading_url_info, to_process)
            echo to_process

            urls = init_urls()
            # to_process = len(urls)
            echo "to_process:" & $to_process
            echo "sleep 10s"
            os.sleep(10000)
            echo "slept"
        

    # for idu, url in urls:
        # if idu <= to_skip:
            # continue
        
        # echo "test3"
        # data = return_request(url, idu)
        # echo "test4"
        # newUrlList = parse_request(data)
        # echo "test5"
        # num_urls_to_add = record_urls(newUrlList)
        # urls = init_urls()
        # echo "sleep 5s"
        # os.sleep(10000)
        # echo "slept"
    

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