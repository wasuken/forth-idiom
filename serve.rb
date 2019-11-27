require 'sinatra'
require 'open-uri'
require 'rexml/document'
require 'uri'
require 'json'

BASE_API_URL = 'http://public.dejizo.jp/NetDicV09.asmx/SearchDicItemLite'

class Idiom
  attr_accessor :value, :arrow_value, :arrow_display
  def initialize(value, arrow)
    @value = value
    @arrow_value = arrow
    @arrow_display = arrow.zero? ? 'value -> answer' : 'value <- answer'
  end
end

def idiom_table_to_four_idioms(idiom_table)
  idiom_arrays = idiom_table.map{|k, v| v.map{|y| y.gsub(Regexp.new(k), '')}}
  memo = Hash.new
  idiom_arrays.each do |idiom_array|
    idiom_array.each do |idiom|
      unless memo.key?(idiom)
        return idiom if idiom_arrays.all?{|ia| ia.include?(idiom)}
      end
    end
  end
  p "unknown"
  return "?"
end

def analyze(idioms)
  idiom_table = Hash.new
  idioms.each do |idiom|
    idiom_table[idiom.value] = []
    uri = URI.encode("#{BASE_API_URL}?Dic=EdictJE&Word=#{idiom.value}&Scope=HEADWORD&Match=CONTAIN&Merge=AND&Prof=XHTML&PageIndex=0&PageSize=1000")
    doc = REXML::Document.new(open(uri).read)
    doc.elements["SearchDicItemResult"]
      .elements
      .each("TitleList/DicItemTitle/Title/span") do |e|
      if e.text.size == 2 && e.text[idiom.arrow_value] == idiom.value
        idiom_table[idiom.value].push e.text
      end
    end
  end
  four_idiom = idiom_table_to_four_idioms(idiom_table)
end

get '/' do
  erb :home
end

post '/idiom' do
  idioms = []
  arrows = params.select{|k, v| k.include?('arrow') }
  values = params.select{|k, v| k.include?('value') && !k.include?('arrow') }
  arrows.each do |ak, av|
    idioms.push Idiom.new(values.find{|vk, vv| ak.include?(vk) }[1], av.to_i)
  end
  answer = analyze(idioms)
  content_type :json
  data = { answer: analyze(idioms)}
  data.to_json
end
