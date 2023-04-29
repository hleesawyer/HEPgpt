## TODO:
    ## 1. Implement the random delay business to the requests
    ## 2. leading_url_info - implement a way to monitor/keep the crawler on a specific domain and not wander around the internet (atlas)
    ## 3. Consider the other crawler obfuscation techniques - proxy, user agents, etc.
    ## 4. Consider fixing the BEWARE line from the robot parser later
    ## 5. Consider converting the rest of the system to object oriented code and functionalizing more of the code
    ## 6. Consider adding an external configurations file for the configurations that will soon be mentioned.


## Prior to running this program, SET THESE CONFIGURATIONS
## 1. Set domain_requirement (example: "twiki.cern.ch" to stay within domains that include that string)
## 2. Set isPublic to true for public domains, false for private domains for which you will need authentication


import std/[strformat, htmlparser, xmltree, strutils, sequtils, os, random, uri, sets]
import std/httpclient, base64
import nimpy



type AtlasScraper = object
  User: string
  Password: string



proc set_client*(self: AtlasScraper, User: string, Password: string, isPublic: bool): HttpClient = 
    ## Initialize the client - will be either a public or private client depending on isPublic.
    ## 
    ## To test the functionality of this proc, use the following with admin/admin as uname/pass:
    ## echo client.getContent("https://httpbin.org/basic-auth/admin/admin")
    ## echo "----------------------AUTH REQUEST MADE----------------------"
    
    var 
        headers: HttpHeaders
        client: HttpClient

    if isPublic == false:

        headers = newHttpHeaders({"Authorization": "Basic " & base64.encode(User & ":" & Password)})
        client = newHttpClient(headers = headers)
        echo "Private client set."

    else:
        client = newHttpClient()
        echo "Public client set."

    return client



proc parse_request*(data: string, urls: seq[string], idu: int): (seq[string], string) = 
    ## ...

    var 
        html = parseHtml(data)
        newUrlsList: seq[string] = @[]
        b: XmlNode


    try:
        # Loop through the a tags found from the html document    
        for a in html.findAll("a"):
            newUrlsList.add(a.attr("href"))
    # If there are no a tags found, an exception occurs probably - test this
    except Exception:
        echo "FAILED 1"
        echo getCurrentExceptionMsg()


    try:
        for b in html.findAll("body"):
            # echo "BODY TAG"
            # parsed_data = $b
            try:
                # Try to record the parsed data
                writeFile(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{urls[idu].replace('/','.')}_parsed.txt", $b)
            except:
                echo "Error: failed to record parsed_data"
                echo getCurrentExceptionMsg()
    except:
        echo "Error: Cannot get body tag."

            
    return (newUrlsList, $b)    



proc return_request*(self: AtlasScraper, User: string, Password: string, request_url: string, idx: int, 
                     to_process: var int, isPublic: bool): (string, int) = 
    ## ...
    

    let 
        domain_requirement: string = "twiki.cern.ch"


    var 
        fixed_request = ""


    echo request_url

    if request_url == "\n":
        return ("", to_process)
    elif domain_requirement notin request_url:
        # If the url does not contain the domain_requirement, then return a blank result
        echo "domain_requirement not satisfied."
        return ("", to_process)
    elif "\n" in request_url:
        echo "its in"
        fixed_request = request_url.replace("\n","")
        echo fixed_request
    elif request_url == "":
        return ("", to_process)  
    else:
        fixed_request = request_url


    # Construct the client
    let client = self.set_client(User, Password, isPublic)
    
    # Make the request
    var d = client.request(fixed_request)
    echo "requested"

    # Get the body data from the request
    var data = d.body()


    # Get the urls from urlFile and construct a set of lines of unique urls
    var lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
    lines = toSeq(toOrderedSet(lines))


    # Delete the line we just processed from urlList
    echo "delete lines"
    lines.delete(idx)
    echo "deleted"
    # Update to_process to reflect the deletion
    to_process = to_process - 1


    # Also, update urlList to reflect this change
    echo "updating urls"
    let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
    defer: f.close()

    # Update urlsAll as well
    let f_all = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlsAll.txt", fmAppend)
    defer: f_all.close()
    

    # Write the lines to finalize the update
    echo "writing lines"
    f.write("\n" & lines)


    # Finalize the new url in urlsAll as well
    echo "urlsAll.txt updated"
    f_all.write("\n" & fixed_request)


    return (data, to_process)



proc remove_url(to_process: var int, idu: int): int =
    ## ...


    var lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
    

    echo "delete lines"
    lines.delete(idu)
    echo "deleted"
    to_process = to_process - 1
    

    echo "updating urls"
    let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
    defer: f.close()
    echo "writing lines"
    

    f.write("\n" & lines)


    return to_process



proc record_urls_main*(f: File, newUrlsList: seq, leading_url_info: string, lines: seq, linesAll: seq, 
                       to_process: var int, num_urls_to_add: var int): (int, int) =

    ## ...
    

    # Loop through the discovered urls and record them in the urlFile
    for url in newUrlsList:
        # Don't add new urls 'url' if it already exists in urlFile.txt
        echo "leadingurlinfo:"
        echo leading_url_info
        echo "url:"
        echo url


        ###################
        # SKIP CONDITIONS #
        ###################

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

        try: # If something happens where we can't process these lines, skip it
            if url & "/" & "\n" in lines or $url[0..^2] & "\n" in lines:
                continue
        except:
           echo "condition error"
        
        if leading_url_info & url & "\n" in linesAll:
            # Skip urls that have already beenp processed and exist in urlsAll.txt
            # http://www.iana.orghttp://pti.icann.org\n
            continue

        if leading_url_info & url & "/" & "\n" in linesAll:
            # Skip urls that have already beenp processed and exist in urlsAll.txt
            # http://www.iana.orghttp://pti.icann.org/\n
            continue

        if url == "/":
            # If the entire new url is '/'
            # http://pti.icann.org
            continue
            
        # If leading_url_info not empty, if it isnt in the url, and if http not in the url
        if leading_url_info != "" and leading_url_info notin url and "http" notin url:
            # http://www.iana.org and http://www.iana.org notin http://pti.icann.org and http notin # http://pti.icann.org
            echo "adding:"
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
            echo "regular url added"

            f.write(url & "\n")
            
            to_process += 1


        num_urls_to_add += 1


    return (num_urls_to_add, to_process)



proc record_urls*(newUrlsList: seq, leading_url_info: string, to_process: var int): (int, int) =    
    ## ...
    

    var 
        num_urls_to_add = 0
        lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
        linesAll = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlsAll.txt".readFile().splitLines(keepEol = true)


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
    ## ...
    
    
    var lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)
    lines = toSeq(toOrderedSet(lines))


    let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt", fmWrite)
    defer: f.close()


    f.write(lines)



proc init_urls*(): seq[string]= 
    ## ...
    

    remove_duplicate_urls()


    var urls = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/urlFile.txt".readFile().splitLines(keepEol = true)


    return urls



proc pr(leading_url_info: string): PyObject =
    ## ...
    

    # When we have the leading_url_info, this is where the robots.txt is stored, so process it
    let sys = pyImport("sys")
    discard sys.path.append(getCurrentDir())


    # Make a nimpy import of the previously constructed roboparser_script that uses robotparser from urllib in python
    let rps = pyImport("robotparser_script")


    try: # Try to parse the robots.txt file

        let rp = rps.parse_robots(leading_url_info & "/robots.txt")

        try: # Try to open and store the file
            # If the file exists
            let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/robotsList.txt", fmAppend)
            f.write(leading_url_info & "/robots.txt" & "\n")
            f.close()

            echo "robots.txt content:"
            echo rp

            return rp

        except Exception:
            # If it does not exist
            let f = open("/home/wrkn/GitRepos/HEPgpt/data-gathering/data/robotsList.txt", fmWrite)
            f.write(leading_url_info & "/robots.txt" & "\n")
            f.close()

            echo "robots.txt content:"
            echo rp
            
            return rp
    except:
        echo "No robots.txt at this domain or domain level."
        return rps



################################################################################################################

if isMainModule:

    ###################
    # INITIALIZATIONS #
    ###################

    
    const 
        minRandDelayInMilliseconds = 5000
        additionalDelayInMilliseconds = 10000
        default_min_delay = 1000


    let 
        isPublic: bool = false
        user_agent: string = "*"
        # py = pyBuiltIns() # FIXME - remove later if this is unused

    
    echo "initializing urls:"
    var 
        uname: string = ""
        pass: string = ""
        newUrlList: seq[string] = @[]
        lines: seq[string] = @[]
        urls: seq[string] = init_urls()
        to_process = len(urls)
        data = ""
        res: Uri
        leading_url_info: string
        num_urls_to_add: int
        idu: int = 0
        rp: PyObject
        parsed_data: string
        asc: AtlasScraper


    if isPublic == false:
        echo "Enter username:"
        uname = readLine(stdin)

        echo "Enter password:"
        pass = readLine(stdin)

        asc = AtlasScraper(User: uname, Password: pass)
    else:        
        # asc takes default uname and pass 
        asc = AtlasScraper(User: uname, Password: pass)

    

    #####################################
    # MAIN LOOP THROUGH URLS TO PROCESS #
    #####################################

    while to_process > 0:


        # Initializations in loop
        urls = init_urls() # Unecessary

        
        while idu <= len(urls)-1:


            # Skip blank entries in urlList
            if urls[idu] == "" or urls[idu] == "\n":
                idu+=1
                continue


            ###################
            # Get Domain Info #
            ###################

            # Try to get a new domain if one exists            
            try:
                # echo "parsing Uri"
                # echo "urls[idu]"
                # echo urls[idu]
                res = parseUri(urls[idu])
                # echo "parsed Uri"

                leading_url_info = res.scheme & "://" & res.hostname

                if leading_url_info == "://":
                    leading_url_info = ""

                echo "leading url info set:"
                echo leading_url_info
            except:
                leading_url_info = ""
                echo "leading url info empty"


            ######################
            # Process Robots.txt #
            ######################

            # Try to process robots.txt for this domain
            try:
                # Get the lines from robotsList.txt and determine if we have already seen and processed it
                # (Untested-ish)Beware: If the robots.txt file is already processed on the very first iteration when running the crawler,
                #  the program will reach an Exception "SIGSEGV illegal storage access" due to rp not existing when trying to run can_fetch
                #  in the next block below. The program assumes that if rp has been processed, then we should be able to execute functions.
                #  Also, I havn't found how to handle exceptions when rp is not initialized
                var robo_lines = "/home/wrkn/GitRepos/HEPgpt/data-gathering/data/robotsList.txt".readFile().splitLines(keepEol = true)
                
                if leading_url_info & "/robots.txt" & "\n" in robo_lines or leading_url_info & "/robots.txt" in robo_lines:
                    echo "robots.txt already processed."
                    # discard # skip robots.txt thats already in the system
                else:
                    # We havn't processed this robots.txt, process it
                    echo "Processing new robots.txt"
                    # discard pr(leading_url_info) # returns either rp which contains parsed robots.txt or the rps module from script
                    rp = pr(leading_url_info) 

            except:
                echo "failed to process"


            # echo "to_process:"
            # echo to_process
            # Skip lines that have already been processed in urlsAll.txt
            # echo "URL:"
            # echo urls[idu]
            # echo "LINES:"
            # echo "idu:"
            # echo idu


            ##############################################
            # MAKE THE REQUEST UNDER THE RIGHT CODITIONS #
            ##############################################

            if urls[idu] != "":
                echo "--------------------------------------------------URL notin lines!"
                

                try:
                    # If the robots.txt allows us to request this url, request it, else avoid it
                    if to(rp.can_fetch(user_agent, urls[idu]), bool) == true:
                        echo "can fetch, requesting url..."
                        (data, to_process) = asc.return_request(uname, pass, urls[idu], idu, to_process, isPublic)
                    else:
                        echo "skipping - cannot fetch or error..."
                        continue
                except:
                    echo getCurrentExceptionMsg()
                    # If there was an error using rp, that means robots.txt doesn't exist or had an error, process request
                    (data, to_process) = asc.return_request(uname, pass, urls[idu], idu, to_process, isPublic)

                
                # urlsAll.txt is updated in return_request(), so update lines to reflext the update
                lines = init_urls()
                echo "lines redefined"
                # echo lines

            else:
                echo "URL in lines!!!------------"
                echo "URL:"
                echo urls[idu]
                
                if urls[idu]=="\n":
                    echo "slashN"

                echo idu

                os.sleep(1000)

                to_process = remove_url(to_process, idu)

                continue


            # echo to_process


            if data == "":
                continue


            #################
            # PARSE REQUEST #
            #################
            
            (newUrlList, parsed_data) = parse_request(data, urls, idu)
            
            ###############
            # RECORD URLS #
            ###############

            # echo to_process
            (num_urls_to_add, to_process) = record_urls(newUrlList, leading_url_info, to_process)
            # echo to_process

            ###################
            # UPDATE ITERATORS #
            ###################

            urls = init_urls()


            # to_process = len(urls)


            echo "to_process:" & $to_process


            echo "sleep some seconds..."


            # Try to get the crawl delay from robots.txt, otherwise set a minimum delay
            try:
                echo to(rp.crawl_delay(user_agent), int)
                echo "crawl_delay found, sleeping..."
                os.sleep(to(rp.crawl_delay(user_agent), int) * 1000) 
            except:
                echo "no crawl delay found, default sleep executed"
                os.sleep(default_min_delay)


            idu+=1
    

    echo "All procesing complete."