#!/usr/bin/env ruby

require 'rubygems'
require 'httparty'
require 'sqlite3'
require 'optparse'

EBAY_CONFIG = YAML::load(File.open("config/ebay.yml"))['development']

class Ebay
  include HTTParty
  # httparty request debug log
  debug_output $stdout

  def self.GetCategoriesRequest
    format :xml

    headers(ebay_headers.merge({"X-EBAY-API-CALL-NAME" => "GetCategories"}))

    requestXml = "<?xml version='1.0' encoding='utf-8'?>
      <GetCategoriesRequest xmlns='urn:ebay:apis:eBLBaseComponents'>
       <CategoryParent>10542</CategoryParent>
       <CategorySiteID>0</CategorySiteID>
       <ViewAllNodes>True</ViewAllNodes>
       <DetailLevel>ReturnAll</DetailLevel>
       <RequesterCredentials>
         <eBayAuthToken>#{auth_token}</eBayAuthToken>
       </RequesterCredentials>
      </GetCategoriesRequest>"

    post(api_url, body: requestXml)
  end

  private

  def self.ebay_headers
  { 'X-EBAY-API-DEV-NAME' => EBAY_CONFIG['dev_name'],
    'X-EBAY-API-APP-NAME' => EBAY_CONFIG['app_name'],
    'X-EBAY-API-CERT-NAME' => EBAY_CONFIG['cert_name'],
    'X-EBAY-API-SITEID' => '0',
    'X-EBAY-API-COMPATIBILITY-LEVEL' => '861',
    'Content-Type' => 'text/xml' }
  end

  def self.auth_token
    EBAY_CONFIG['auth_token']
  end

  def self.api_url
    EBAY_CONFIG['uri_sandbox']
  end

end

response = Ebay.GetCategoriesRequest

# Check correct response or show error message
if response.parsed_response['GetCategoriesResponse']['Ack'] != 'Success'
  puts response.parsed_response['GetCategoriesResponse']['Errors']['LongMessage']
  exit 1
else
  categories = response['GetCategoriesResponse']['CategoryArray']['Category']
end

# ------------ Ruby Command line parser -------

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner = "Usage: Select one of the following options"
  opt.separator  "Options"

# ------------ rebuild option: create database
  opt.on("--rebuild","Create and populate the ebay categories database") do
    begin
      # Delete categories db if already exists
      File.delete("./categories.db") if File.exists?("./categories.db")
      # Create DB
      db = SQLite3::Database.new "categories.db"
      # Create categories table
      db.execute "CREATE TABLE IF NOT EXISTS Categories(CategoryID INTEGER,
        CategoryName TEXT, CategoryLevel INT, BestOfferEnabled BOOL,
        CategoryParentID INTEGER, LeafCategory BOOL, LSD BOOL)"
      # Loop through each categories and insert values
      categories.each do |category|
        category_id = category['CategoryID']
        category_name = category['CategoryName']
        category_level = category['CategoryLevel']
        best_offer_enabled = category['BestOfferEnabled']
        category_parent_id = category['CategoryParentID']
        leaf_category = category['LeafCategory']
        lsd = category['LSD']
        db.execute("INSERT INTO categories (CategoryID,
          CategoryName, CategoryLevel, BestOfferEnabled, CategoryParentID, LeafCategory, LSD)
          VALUES (?, ?, ?, ?, ?, ?, ?)", [category_id, category_name, category_level,
          best_offer_enabled, category_parent_id, leaf_category, lsd])
      end
    rescue SQLite3::Exception => e
      puts "Exception occurred"
      puts e
    ensure
      db.close if db
    end

    puts "Created and populated ebay categories database"
  end

# ------------ render option: retrieve data from CATEGORY_ID
  opt.on("--render CATEGORY_ID","output a file named CATEGORY_ID.html that
     contains a simple web page displaying the category tree rooted at the given ID") do |category_id|
    options[:category_id] = category_id
    begin
      # Open categories.db
      db = SQLite3::Database.open "categories.db"
      db.results_as_hash = true
      results = db.execute("SELECT * FROM categories WHERE CategoryParentID LIKE '#{category_id}%'")
      if !results.empty?
        # Create HTML file
        File.open("#{category_id}.html", "w") do |file|
          file.write( <<-HTML
            <html>
            <head>
            </head>
            <body>
              <h3>Category: #{category_id}</h3>
              <table style="width:100%">
                <tr>
                  <td>CategoryID</td>
                  <td>CategoryName</td>
                  <td>CategoryLevel</td>
                  <td>BestOfferEnabled</td>
                </tr>
            HTML
          )
          results.each do |result|
          file.write( <<-HTML
            <tr>
              <td>#{result['CategoryID']}</td>
              <td>#{result['CategoryName']}</td>
              <td>#{result['CategoryLevel']}</td>
              <td>#{result['BestOfferEnabled']}</td>
            </tr>
             HTML
           )
          end
          file.write( <<-HTML
              </table>
            </body>
            </html>
            HTML
          )
        end
        puts "Successfully created #{category_id}.html"
      else
        puts "No category with ID: #{category_id}"
      end
    rescue SQLite3::Exception => e
      puts "Exception occurred"
      puts e
    ensure
      db.close if db
    end
  end

# ------------ help option
  opt.on("--help","help") do
    puts opt_parser
  end
end

opt_parser.parse!
