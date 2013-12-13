# -*- coding: utf-8 -*-
# Copyright (C) garin <garin54@gmail.com> 2011
# See the included file COPYING for details.
require "mok2html_element"
require "cgi"

module Mok
  class Mok2Html
    VERSION = File.readlines(File.join(File.dirname(__FILE__),"../VERSION"))[0].strip
    RELEASE = File.readlines(File.join(File.dirname(__FILE__),"../RELEASE"))[0].strip

    def initialize(src, options = {})
      @debug = true

      # options
      @css = files_to_str(options[:css])
      @js  = files_to_str(options[:js])
      @language = options[:language]
      @index = options[:index]
      @metadata = options[:metadata]
      @quiet = options[:quiet]

      get_customized_element(options[:custom_element]) unless options[:custom_element].empty?
      @mok = BlockParser.new(options)
      @metadata = setup_metadata
      @nodes = @mok.parse src
    end

    # 複数ファイルの文字列を返す
    # files: ファイルの配列または","区切り文字列
    def files_to_str(files = [])
      files = files.split(",") unless defined? files.each
      files.map do |f|
        path = File.expand_path(f.strip)
        File.open(path).readlines.join + "\n" unless path.empty?
      end.join
    end

    # エレメントのカスタム用ファイルを読み込む
    def get_customized_element(file)
      require File.expand_path(file)
    end

    def setup_metadata
      metadata = @mok.metadata
      metadata[:language] = @language if metadata[:language].nil?
      metadata
    end

    def to_html
      html = ""
      html += header unless @quiet
      html += header_title
      html += metadata if @metadata
      html += index if @index
      html += body
      html += footnote
      html += footer unless @quiet
      html
    end

    def body
      @nodes.map do |node| node.apply end.join
    end

    def index
      return "" if @mok.index[:head].nil?
      str = "<div id='mok-index'>"
      level_pre = 1
      @mok.index[:head].each_with_index do |h,i|
        next if h[:level] == 1 or h[:level] == 6

        if h[:level] == 5
          str += %[<div class="nonum"><span class="space"></span><a href="#mok-head#{h[:level]}-#{i+1}">#{CGI.escapeHTML(h[:title])}</a></div>\n]
        else
          str += index_terminate(h[:level], level_pre)
          str += "<li><a href='#mok-head#{h[:level]}-#{i+1}'>#{h[:index]}#{h[:title]}</a>\n"
          level_pre = h[:level]
        end
      end
      str += index_terminate(2, level_pre) + "</ul>"
      str += "</div>"
      str
    end

    def index_terminate(level, level_pre)
      str = ""
      case level <=> level_pre
      when 1
        (level - level_pre).times do
          str += "<ul>"
        end
      when -1
        (level_pre - level).times do
          str += "</ul></li>"
        end
      else
        str += "</li>"
      end
      str
    end

    def metadata
      str = "<div id='mok-metadata'>"
      str += %[<div>#{CGI.escapeHTML(@metadata[:description])}</div>] unless @metadata[:description].nil?
      str += %[<ul class="list-inline">]
      %w{ author create update publisher version tag }.each do |m|
        str += %[<li><strong>#{m}</strong>:#{CGI.escapeHTML(@metadata[m.to_sym])}</li>] unless @metadata[m.to_sym].nil?
      end
      str += "</ul>"
      str += "</div>"
      str
    end

    def footnote
      return "" if @mok.inline_index[:footnote].nil?
      str = "<div id='mok-footnote'>"
      @mok.inline_index[:footnote].each_with_index do |f,i|
        str += %[<a id="mok-footnote-#{i+1}" class="footnote"></a>]
        str += %[<a href="#mok-footnote-#{i+1}-reverse" class="footnote-reverse">*#{i+1}</a>]
        str += " #{f[:content].map{|c| c.apply}}<br>"
      end
      str += "</div>"
      str
    end

    def header
      str = <<EOL
<!DOCTYPE html>
<html lang="#{@metadata[:language]}">
  <head>
    <meta charset="utf-8">
EOL
      str += css
      str += javascript
      str += <<EOL
  <title>#{CGI.escapeHTML(@metadata[:subject])}</title>
  </head>
<body>
EOL
    end

    def header_title
      "<h1>#{CGI.escapeHTML(@metadata[:subject])}</h1>\n"
    end

    def css
      str = ""
      str += %[<style type="text/css"><!--\n#{@css}\n--></style>\n] unless @css.empty?
      str
    end

    def javascript
      str = ""
      str += %[<script type="text/javascript">#{@js}</script>\n] unless @js.empty?
      str
    end

    def footer
      str = "\n"
      str += "<div id='rights'>#{@metadata[:rights]}</div>\n" unless @metadata[:rights].nil?
      str += "</body>\n</html>"
      str
    end
  end
end
