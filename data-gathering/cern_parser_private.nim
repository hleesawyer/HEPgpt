import std/strformat
import std/htmlparser
import std/xmltree
import httpclient, base64
import std/os
import strutils


type AtlasScraper = object
  User: string
  Password: string


proc set_client*(self: AtlasScraper, User: string, Password: string): HttpClient = 

  echo "1"
  let 
    headers = newHttpHeaders({"Authorization": "Basic " & base64.encode(User & ":" & Password)})
    client = newHttpClient(headers = headers)

  echo "2"
  # echo client.getContent("https://httpbin.org/basic-auth/admin/admin")
  # echo "----------------------REQUEST 1----------------------"
  # echo client.getContent("https://atlas.cern/user/login")
  # echo "----------------------REQUEST 1 COMPLETE----------------------"

  return client


proc parse_request*(self: AtlasScraper, data: string): XmlNode = 

  echo "3"
  var html = parseHtml(data)
  # echo $html

  echo "4"
  for a in html.findAll("a"):
    echo "wtf"
    echo a
    return a
    # if a.attrs.hasKey "href":
      # echo a.attrs["href"]

  # return a #parsed_data


proc get_auth_request*(self: AtlasScraper, client: HttpClient, url: string, idx: int): string = 

  echo "6"

  # data = client.getContent("https://cern.ch/atlas-collaboration")
  try:
    var data = client.getContent(url)
  except Exception:
    echo "failed to get content"
    echo getCurrentExceptionMsg()

  # parsed_data = self.parse_request(data)

  # writeFile(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{url.replace('/','.')}_{idx}.txt", parsed_data)

  # For the test case, lets get a single dump of the atlas collaboration website
  echo "7"
  writeFile(&"/home/wrkn/GitRepos/HEPgpt/data-gathering/data/{url.replace('/', '~')}_{idx}.txt", data)
  echo &"Request {idx} Complete."
  


if isMainModule:
  
  echo "username:"
  let uname = readLine(stdin)

  echo "password:"
  let pass = readLine(stdin)

  echo "8"
  var 
    s = AtlasScraper(User: uname, Password: pass)
    urlList: seq[string]

  # https://cern.ch/atlas-collaboration

  echo "9"
  urlList = @["www.example.com"]
  # urlList = @["https://cern.ch/atlas-collaboration"]
  let client = s.set_client(uname, pass)
  echo "10"
  for idx, url in urlList:
    echo "11"
    discard s.get_auth_request(client, url, idx)

  






#[
var session = newHttpClient(timeout = 20000)

proc login(session: HttpClient, url: string, email: string, password: string): bool =
  let
    formData = {"email": email, "password": password}
    headers = {"User-Agent": "Mozilla/5.0"}

  let response = session.postFormData(url, formData, headers)
  if response.status == Http200:
    echo "Login successful"
    return true
  else:
    echo "Login failed"
    return false

if login(session, url, email, password):
  let response = session.get("https://example.com/protected-page")
  let document = parse(response.body)
  # scrape website as needed
  echo document.body
else:
  quit(1)
]#

####################
  #[

import httpclient, strutils

# Define the login credentials
const
  username = "your_username"
  password = "your_password"

# Create a `HttpClient` instance
var client = newHttpClient()

# Prepare the login request
let
  url = "https://example.com/login"
  headers = {"Content-Type": "application/x-www-form-urlencoded"}
  body = "username=" & urlEncode(username) & "&password=" & urlEncode(password)

# Send the login request
let response = client.post(url, headers, body)

# Check the response status code
if response.statusCode == 200:
  # Login successful, perform scraping or other actions
  echo "Login successful!"
  # ...
else:
  # Login failed, handle error
  echo "Login failed with status code: ", response.statusCode
  echo "Response body: ", response.body


  ]#
