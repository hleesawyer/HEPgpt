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
