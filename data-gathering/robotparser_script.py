from urllib.robotparser import RobotFileParser
import urllib.request


def parse_robots(url: str):
    rp = RobotFileParser()

    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Python'})) as response:
        rp.parse(response.read().decode("utf-8").splitlines())

    return rp



if __name__ == "__main__":

    url = input("What robots.txt url would you like to parse?:")

    parse_robots(url)