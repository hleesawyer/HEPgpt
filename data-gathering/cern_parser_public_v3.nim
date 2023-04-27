#[
import
  asyncdispatch, asyncnet, htmlparser, xmltree, httpclient, strutils,
  strtabs, streams, uri, sets

var visited = initHashSet[string]()

proc crawl(url: string) {.async.} =
    var client = newAsyncHttpClient()
    # client.onProgressChanged = onProgressChanged


    if url in visited: return # Already visited this URL.
    echo("Crawling ", url)
    visited.incl(url)

    let resp = await client.get(url)

    if resp.status.startswith("200") and resp.headers["Content-Type"] == "text/html":
        # var data = resp.body()
        let html = parseHtml(newStringStream(resp.body()))
        for a in html.findAll("a"):
            let href = a.attrs["href"]
            if href != "":
                if href.startswith("http://"):
                    waitFor crawl(href)
                else:
                    let fullUrl = TUrl(url) / TUrl(href)
                    # We reuse this client because the connection is kept alive.
                    waitFor crawl($fullUrl, client)
]#

# Progress Reporting not working
# proc onProgressChanged(total, progress, speed: BiggestInt) {.async.} =
    # echo("Downloaded ", progress, " of ", total)
    # echo("Current rate: ", speed div 1000, "kb/s")


# while true:
    # waitFor crawl("http://nimrod-lang.org")