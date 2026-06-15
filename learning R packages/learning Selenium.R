################################################################################
#' Understanding Selenium for controlling a web browser
#' 2026-06-15
#' 
#' Selenium allows for programmatic control of a web browser. This enables
#' automation in retrieval of webpages or web interactivity. It can be the only
#' way to retrieve info from dynamic pages.
#' 
#' However, it is less stable than web scraping via URL or API calls. Hence
#' these methods should be prefered in place of Selenium where possible.
#' 
################################################################################

## software setup --------------------------------------------------------- ----

# The connection process is
# R >> RSelenium >> Selenium Server >> geckodriver >> Firefox (Marionette)
#
# The components are:
# 
# Firefox - a modern browser and one that was suggested as being easy to setup
# Marionette - the automation driver for Gecko's engine
# geckodriver - a proxy for connecting WebDrivers to browsers
# Selenium - WebDriver for web browser automation
# RSelenium - a set of R bindings for the 'Selenium 2.0 WebDriver'

# Several of these require installation:
# 
# Firefox is installed as per normal from internet
# 
# Selenium Server is fetched from GitHub
# https://github.com/SeleniumHQ/selenium/releases
# The version 4.x.y caused errors during testing
# The version 2.x.y was too old
# Hence we are using the final version 3.141.59
# Downloaded the file selenium-server-standalone-3.141.59.jar from the release
# 
# Geckodriver is fetched from GitHub
# https://github.com/mozilla/geckodriver/releases
# We started with the latest version and had no problems
# The win64 zip contains geckodriver.exe
# 
# Marionette is installed as part of either Firefox or Geckodriver
# (most likely Firefox).
# 

# Once ready to run we have:
# - Firefox installed
# - Project folder containing
#    selenium-server-standalone-3.141.59.jar
#    geckodriver.exe
#    geckodriver-v0.37.0-win64.zip (the zip that contained the exe)
#

## starting server -------------------------------------------------------- ----

# Starting Selenium server
#
# It appears to work better to start the Selenium server outside of R.
# We do this in PowerShell using:
#
# java "-Dwebdriver.gecko.driver=C:\NotBackedUp\selenium\geckodriver.exe" -jar "C:\NotBackedUp\selenium\selenium-server-standalone-3.141.59.jar"
# 
# The PowerShell session remains open until we are done.
# We can verity this is working by navigating to:
# http://127.0.0.1:4444/wd/hub/status
# or
# http://127.0.0.1:4444/status
# in a browser.
# 

## confirming selenium server is visible to R------------------------------ ----

# internal R test
readLines("http://127.0.0.1:4444/status", warn = FALSE)
readLines("http://127.0.0.1:4444/wd/hub/status", warn = FALSE)
# only one of these is likely to work properly

# basic connection
con <- socketConnection(host = "127.0.0.1", port = 4444, blocking = TRUE, open = "r+b", timeout = 5)
isOpen(con)
close(con)

# simple read test 1
con <- socketConnection(host = "127.0.0.1", port = 4444, blocking = TRUE, open = "r+b", timeout = 5)

writeChar(
  "GET /status HTTP/1.1\r\nHost: 127.0.0.1:4444\r\nConnection: close\r\n\r\n",
  con,
  eos = NULL
)

resp <- readLines(con, warn = FALSE)
close(con)

print(resp)

# simple read test 2
con <- socketConnection(host = "127.0.0.1", port = 4444, blocking = TRUE, open = "r+b", timeout = 5)

writeChar(
  "GET /wd/hub/status HTTP/1.1\r\nHost: 127.0.0.1:4444\r\nConnection: close\r\n\r\n",
  con,
  eos = NULL
)

resp <- readLines(con, warn = FALSE)
close(con)

print(resp)
# only one of test 1 or 2 is likely to work

## activate a selenium connection from R ---------------------------------- ----

library(RSelenium)

remDr <- remoteDriver(
  remoteServerAddr = "127.0.0.1",
  port = 4444L,
  browserName = "firefox",
  path = "/wd/hub"
)

remDr$open()
# Firefox opens automatically
# Has icon indicating browser is under remote control by Marionette

# can change page (browser display changes)
remDr$navigate("URL OF FAVOURITE PAGE HERE")
# can retrieve values
remDr$getTitle()
# can close browser (browser closes)
remDr$close()

## basic fetch from webpage ----------------------------------------------- ----

# PowerShell
# java "-Dwebdriver.gecko.driver=C:\NotBackedUp\selenium\geckodriver.exe" -jar "C:\NotBackedUp\selenium\selenium-server-standalone-3.141.59.jar"

library(RSelenium)

# connect
remDr <- remoteDriver(
  remoteServerAddr = "127.0.0.1",
  port = 4444L,
  browserName = "firefox",
  path = "/wd/hub"
)

# open firefox
remDr$open()

# change page
remDr$navigate("ENTER WEBPAGE URL HERE")

# finding elements
remDr$findElements(using = "", value = "")

# options for `using` include:
# xpath
# css selector
# id
# name
# class name
# tag name

# `value` can be retrieved from developer tools
# inspect HTML
# find component of interest
# then
# - right-click > copy > xpath
# - right-click > copy > css path
# - read id, name, or tag direct from html
#

# example finding elements - get all URL links
all_urls = remDr$findElements(using = "tag name", value = "a")
all_urls = remDr$findElements(using = "css selector", value = "p a") # copied css path, kept last two elements (paragraph & link)
all_urls = remDr$findElements(using = "xpath", value = "//main//a") # copied xpath, kept main and link
# all links by itself is crude
# more likely you want css selector or xpath to find links in a specific area


# raw elements are not human readable, need to extract attributes
single_url = all_urls[[1]]

single_url$getElementLocation()
single_url$getElementSize()
single_url$getElementText()
single_url$getElementAttribute("href")
single_url$getElementAttribute("text")

# all text and links
df_link = data.frame(
  text = sapply(all_urls, function(x){ x$getElementAttribute("text")[[1]] }),
  href = sapply(all_urls, function(x){ x$getElementAttribute("href")[[1]] }),
  stringsAsFactors = FALSE
)

# click an element (a link)
to_click = all_urls[[1]]
to_click$clickElement() # clicks link, page changes
Sys.sleep(2) # wait for page to load


# example finding elements - get all images
all_imgs = remDr$findElements(using = "tag name", value = "img")

# raw elements are not human readible, extract
single_img = all_imgs[[1]]

single_img$getElementAttribute("src")

# save image
tryCatch({
  img_url = unlist(single_img$getElementAttribute("src"))
  
  download.file(img_url, destfile = "./img.svg", mode = "wb")
}, error = function(e){
  print("Failed to download")
})

## adding text to web forms ----------------------------------------------- ----

library(RSelenium)

remDr <- remoteDriver(
  remoteServerAddr = "127.0.0.1",
  port = 4444L,
  browserName = "firefox",
  path = "/wd/hub"
)
remDr$open()

# navigate to web page with text box
remDr$navigate("URL GOES HERE")

# locate text box
text_areas = remDr$findElements(using = "tag name", value = "textarea")
# there are two boxes, only one has an id
ids = sapply(text_areas, function(x){ x$getElementAttribute("id") })
id = unlist(ids[ids != ""])
# locate element with id
text_area = remDr$findElement(using = "id", value = id)

# put text in text box
text_area$sendKeysToElement(list("apple pie"))
text_area$sendKeysToElement(list("\n")) # a new line character, not 'enter' to trigger webpage response

text_area$clearElement()

text_area$sendKeysToElement(list("apple pie", key = "enter"))
# this works - but webpage can detect non-human user

# other ways to locate a text box
# text_box = remDr$findElement(using = "css", "input[type='text']")
# text_box = remDr$findElement(using = "name", value = "q")

# close browser
remDr$close()

## code of conduct & terms of service ------------------------------------- ----

# Many websites
# (1) monitor for patterns of automated access & use (i.e. to detect bots)
# (2) prohibit the use of bots or automation in access requests
# 
# The prohibition is generally made on the basis of mode-of-access. So fetching
# one web-page a minute in an automated manner is not permitted, while fetching
# 100 pages a minute manually is permitted.
# 
# Review the terms and conditions of any website you intend to interact with
# via Selenium before doing so, to ensure use is permitted.
# 
