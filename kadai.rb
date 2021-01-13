# coding: utf-8

require "socket"
require "cgi/util"
require "pathname"
require "json"
require "uri"

THREADS_FILE = Pathname(__dir__) / "threads.json"
ss = TCPServer.open(8080)

def get_thread_item(thread)
  <<~EOHTML
    <a href="#{thread["id"]}" class="thread-item__content">
      <h2>#{thread["name"]}</h2>
    </a>
  EOHTML
end

def get_thread_list_page(threads)
  thread_items = []
  for thread in threads do
    thread_items.push(get_thread_item(thread))
  end 
  <<~EOHTML
    <h1>スレッド一覧</h1>
    <form method="post">
      <label>スレッド名：<input type="text" name="name" placeholder="スレッド名を入力"></label>
      <input type="submit" value="send">
    </form>
    <h2>
    #{ thread_items.join("\n") }
  EOHTML
end

def get_comment_item(comment)
  <<~EOHTML
    <div>
      <p>
        #{comment["creator_name"]}:#{comment["created_at"]}
        #{comment["comment"]}
      </p>
      <hr>
    </div>
  EOHTML
end

def get_thread_detail_page(thread, comments)
  comment_items = []
  for comment in comments do
    comment_items.push(get_comment_item(comment))
  end
  <<~EOHTML
    <a href="/">一覧に戻る</a>
    <h1>#{thread["name"]}</h1>
    <hr>
    <form method="post">
      <label>name：<input type="text" name="name" placeholder="名前を入力"></label>
      <label>comment：<input type="text" name="comment" placeholder="コメントを入力"></label>
      <input type="submit" value="send">
    </form>
    <hr>
    #{ comment_items.join("") }
  EOHTML
end

def get_json_data
  open(THREADS_FILE) do |j|
    JSON.load(j)
  end
end

def get_next_index(array)
  if array.length > 0
    array.map{ |a| a["id"] }.max + 1
  else
    0
  end
end

loop do
  Thread.start(ss.accept) do |s|
    is_html = true
    request = s.gets


    method, path = request.split                    # In this case, method = "POST" and path = "/"
    headers = {}
    while line = s.gets.split(" ", 2)              # Collect HTTP headers
      break if line[0] == ""                            # Blank line means no more headers
      headers[line[0].chop] = line[1].strip             # Hash headers by type
    end
    raw_data = s.read(headers["Content-Length"].to_i)  # Read the POST data as specified in the header
    data = Hash[URI.decode_www_form(raw_data)]

    json_data = get_json_data
    if !json_data
      json_data = {
        "threads": [],
        "comments": []
      }
    end
    puts json_data
    
    if path == "/" 
      threads_data = []
      threads = json_data["threads"]

      if method == "POST" && data["name"]
        thread = {}
        thread["id"] = get_next_index(threads)
        thread["name"] = data["name"]
        json_data["threads"].unshift(thread)
        threads.unshift(thread)
        open(THREADS_FILE, "w") do |j|
          JSON.dump(json_data, j)
        end
      end


      status = "200 OK"
      header = "Content-Type: text/html; charset=utf-8"

      body = get_thread_list_page(threads)
    elsif path.match(/\/[a-zA-Z\d]*.css$/)
      is_html = false
      header = "Content-Type: text/css; charset=utf-8"
      begin
        status = "200 OK"
        body = File.read(path.split('/')[1])
      rescue => error
        status = "404"
        body = ""
      end
    elsif path.match(/\/[0-9]+/)
      id = path.match(/[0-9]+/)[0].to_i
      thread = json_data["threads"].filter{ |thread| thread["id"] == id }[0]
      comments = json_data["comments"].filter{ |comment| comment["thread_id"] == id }
      
      if thread
        if method == "POST" && data["name"] && data["comment"]
          comment = {}
          comment["id"] = get_next_index(comments)
          comment["thread_id"] = id
          comment["created_at"] = Time.now
          comment["creator_name"] = data["name"]
          comment["comment"] = data["comment"]
          json_data["comments"].unshift(comment)
          comments.unshift(comment)
          open(THREADS_FILE, "w") do |j|
            JSON.dump(json_data, j)
          end
        end
        status = "200 OK"
        header = "Content-Type: text/html; charset=utf-8"
        body = get_thread_detail_page(thread,comments)
      else
        status = "404"
      end
    else
      status = "404"
    end

    s.write(<<~EOHTTP)
      HTTP/1.0 #{status}
      #{header}

      #{
        if is_html
          <<~EOHTML
            <html>
              <head>
                <link href="index.css" rel="stylesheet">
                <link href="normalize.css" rel="stylesheet">
              </head>
              <body>
                #{body}
              </body>
            </html>
          EOHTML
        else
          <<~EOHTML
            #{body}
          EOHTML
        end
      }
    EOHTTP

    puts "#{Time.new} #{status} #{path}"
    puts request
    puts data
    s.close
  end
end
