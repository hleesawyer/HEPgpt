import htmlparser, httpclient

# const url = "https://example.com/login"
# const email = "you@example.com"
# const password = "your_password"

var session = newHttpClient()

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
