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
      @css = File.open(File.expand_path(options[:css])).readlines.to_s unless options[:css].empty?
      @js  = File.open(File.expand_path(options[:js])).readlines.to_s unless options[:js].empty?
      @language = options[:language]
      @index = options[:index]
      @metadata = options[:metadata]
      @quiet = options[:quiet]

      get_customized_element(options[:custom_element]) unless options[:custom_element].empty?
      @mok = BlockParser.new(options)
      @metadata = setup_metadata
      @nodes = @mok.parse src
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
          str += %[<div class="nonum"><a href="#mok-head#{h[:level]}-#{i+1}"><span class="space" />#{h[:title]}</a></div>\n]
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
        str += "<a id='mok-footnote-#{i+1}' class='footnote' />"
        str += "<a href='#mok-footnote-#{i+1}-reverse' class='footnote-reverse'>*#{i+1}</a>"
        str += " #{f[:content].map{|c| c.apply}}<br />"
      end
      str += "</div>"
      str
    end

    def header
      str = <<EOL
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="#{@metadata[:language]}">
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
EOL
      str += css
      str += javascript
      str += <<EOL
  <title>#{@metadata[:subject]}</title>
  </head>
<body>
EOL
    end

    def header_title
      "<h1>#{@metadata[:subject]}</h1>\n"
    end

    def css
      str = ""
      str += %[<style type="text/css"><!--\n#{@css}\n--></style>\n] unless @css.nil?
      str
    end

    def javascript
      str = ""
      str += %[<script type="text/javascript">#{@js}</script>\n] unless @js.nil?
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
