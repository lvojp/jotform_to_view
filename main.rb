#! /usr/bin/env ruby
#
require 'csv'
require 'tel_formatter'
require 'fileutils'

# require 'rubygems'
# require 'active_support'

class DataConvertor

  def jpy_comma(n)
    return n.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,') +"円"
  end

  def delete_semicolon(s)
    return s.gsub(';',',')
  end

  def remove_total_time(s)
    return s.to_s.gsub(/\(.+\)/,'')
  end

  def tel_format(s)
    if(s == "") then
      return ""
    else
      #固定電話
      if(s.length != 11)then
        return TelFormatter.format(s)
        #cellphone
      else
        first = s.slice(0,3)
        middle = s.slice(3,4)
        last = s.slice(6,4)
        return first + "-" + middle + "-" + last
      end
    end
  end

  def delete_totaltime(s)
    return s.to_s.gsub(/\(.+\)/,'')
  end

  def format_postalcode(n)
    return n.slice(0, 3) + '-' + n.slice(3,n.length);
  end

  #紹介文章などが改行されているとCSVファイルが崩れてしまう事に対応
  def delete_returns(s)
    return s.gsub(/(\s)/," ")
  end

  #jotformサーバーに半角スペースや（）付きでアップされた画像ファイルの文字コードが変更されている物を元に戻す
  def convert_chars(s)
    s = s.gsub('%28','(')
    s = s.gsub('%29',')')
    s = s.gsub('%20',' ')
    s = s.gsub('&amp;','&')
    return s
  end


  
end



class Jotform

  def initialize
    @table = CSV.read("jot_input.csv", headers: true, encoding: "UTF-8")
    # @pic_cells = ["びゅ〜画像1","びゅ〜画像2","びゅ〜画像3"] 
    @pic_cells = ["会社の広告画像"] 
    @money_cells = ["月額給与 (下限)","月額給与 (上限)","日額給与 (下限)","日額給与 (上限)","通勤手当上限金額","時給 (下限)","時給 (上限)"]
    @multi_select_cells = ["定休日","各種条件","必要資格"]
    @telephone_cells = ["電話番号(固定)","電話番号(携帯)","FAX番号"]
    @time_cells = ["営業時間","勤務時間A","勤務時間B","勤務時間C"]
    # @introduce_cells = ["びゅ〜紹介文章1","びゅ〜紹介文章2","応募資格詳細","待遇詳細","お仕事内容詳細"]
    @introduce_cells = ["応募資格詳細","待遇詳細","お仕事内容詳細"]
    @require_skill = ["必要資格"]
    @custom_header = []
    FileUtils.mkdir_p("view") unless FileTest.exist?("view")
  end

  # 写真リストを作る
  def gather_pics
    result = []
    @table.each{|row|
      result.push(row[@pic_cells[0]])
      result.push(row[@pic_cells[1]])
      result.push(row[@pic_cells[2]])
    }
    result.delete("")
    return result
  end

  # wget 用ダウンロードのリストを作る
  def make_dl_list
    pics = gather_pics()

    File.open("view/picList.txt", "w") do |f|
      pics.each{|c|
        f.puts(c)
      }
    end
  end

  def rewrite_cells
    make_jpg_path
    add_comma
    del_semicolon
    add_tel_hyphen
    del_totaltime
    del_returns
    add_postalcode_hyphen
    set_no_comment
  end


  # 画像データの入っている列の画像のDL先文字列をローカル参照用のパスに変更する
  def make_jpg_path
    @table.each{|row|
      @pic_cells.each{|pos|
        if ! (row[pos].to_s.empty?)then
          dc = DataConvertor.new
          temp = dc.convert_chars(jpg_name(row[pos]))
          row[pos] = ".:imgs:" + temp
          # row[pos] = ":Users:kunio:Desktop:view_test:img:" + temp
          # row[pos] = "mainSSD:Users:kunio:Desktop:view_test:img:" + temp
          #row[pos] =  temp
        end
      }
    }
  end

  def add_comma
    dc = DataConvertor.new
    @table.each{|row|
      @money_cells.each{|pos|
        if(row[pos]!="")then
          row[pos] = dc.jpy_comma(row[pos])
        end
      }
    }
  end

  def del_semicolon
    dc = DataConvertor.new
    @table.each{|row|
      @multi_select_cells.each{|pos|
        row[pos] = dc.delete_semicolon(row[pos])
      }
    }
  end

  def add_tel_hyphen
    dc = DataConvertor.new
    @table.each{|row|
      @telephone_cells.each{|pos|
        if(row[pos] != "")then 
          if(pos == "電話番号(固定)")then
            row[pos] = "固定電話:" + dc.tel_format(row[pos])
          elsif(pos == "電話番号(携帯)")then
            row[pos] = "電話:" + dc.tel_format(row[pos])
          elsif(pos == "FAX番号")then
            row[pos] = "FAX:" + dc.tel_format(row[pos])
          end
        end
      }
    }
  end

  def del_totaltime
    dc = DataConvertor.new
    @table.each{|row|
      @time_cells.each{|pos|
        row[pos] = dc.delete_totaltime(row[pos])
      }
    }
  end

  def add_postalcode_hyphen
    dc = DataConvertor.new
    @table.each{|row|
      row['郵便番号'] = dc.format_postalcode(row['郵便番号'])
    }
  end

  def del_returns
    dc = DataConvertor.new
    @table.each{|row|
      @introduce_cells.each{|pos|
        row[pos] = dc.convert_chars(dc.delete_returns(row[pos]))
      }
    }
  end

  def set_no_comment
    dc = DataConvertor.new
    @table.each{|row|
      @require_skill.each{|pos|
        if(row[pos] == "")then
          row[pos] = "特になし"
        end
      }
    }
  end
  

  # indesignで画像の参照用カラムのヘッダーには接頭辞として"@"が必要なので、これを追加
  def rewrite_header
    idx = []
    @pic_cells.each{|p|
      idx.push(@table.headers.index(p)) 
    }
    @table.headers.each{|s| @custom_header.push(s)
    }

    idx.each{|n|
      @custom_header[n] = "@" + @custom_header[n]
      p @custom_header[n]
    }

  end

  # 必要な変更を加えたCSVファイルを出力
  def out_csv
    change_header()
    CSV.open("view/dat.csv",'w',:headers => @custom_header ,:write_headers => true ) do |file|
      # CSV.open("for_view.csv", "a:Windows-31J", :headers => @custom_header, :write_headers => true) do |file|   
      @table.each{|row|
        file << row
      }
    end
  end

  def change_header
    # p @table["画像Aの追加"].pos
    # @pic_cells.each{|pos|
    # 	@table.headers[pos] = "@" + @table.headers[pos]
    # }
  end	

  # メンテ用。画像の一覧を表示する
  def show_pic_cell
    @table.each{|row|
      @pic_cells.each{|pos|
        if(row[pos].to_s != "")then
          p jpg_name(row[pos])
        end
      }
    }
  end

  # 画像のURLの入っているセルのデータから、画像のファイル名を抽出する
  def jpg_name(s)
    pos = s.rindex("/")
    result = s[pos+1,s.length]
    return result
  end

end

jf = Jotform.new
jf.rewrite_header
jf.make_dl_list
jf.rewrite_cells
# jf.show_pic_cell
jf.out_csv

`nkf -s --overwrite ./view/dat.csv`
# `mkdir ./view/imgs; cd ./view/imgs; wget -i ../picList.txt`
