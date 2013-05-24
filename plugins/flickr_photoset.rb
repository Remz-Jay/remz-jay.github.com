require "flickraw"
require "active_support/memoizable"
#require "debugger"

class FlickrSet < Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @markup = markup
    @user_id = markup.split(" ")[0]
    @maxitems = markup.split(" ")[1]
  end

  def render(context)
    FlickRaw.api_key = ENV["FLICKR_KEY"]
    FlickRaw.shared_secret = ENV["FLICKR_SECRET"]

    output = []
    if @maxitems.nil?
      set = flickr.photosets.getList(user_id: @user_id)
    else
    	set = flickr.photosets.getList(user_id: @user_id, per_page: @maxitems, page: 1)
    end

    set.each do |item|
      #setinfo = flickr.photosets.getInfo(photoset_id:item.id)
      #output << "<p>#{item.title}(#{item.primary})</p>"
      info = flickr.photos.getInfo(photo_id:item.primary)
      src  = FlickRaw.send("url_n", info)
      page_url = FlickRaw.url_photopage(info)
      img_tag = "<img src=\"#{src}\" class=\"aside-flickr\" title=\"#{info.title}\"/>"
      output << "<li>"
      output << "<a href=\"#{page_url}\" target=\"_blank\">#{img_tag}</a>"
      output << "<h2><a href=\"#{page_url}\">#{item.title}</a></h2>"
      output << "<p>#{item.description}</p>"
      output << "</li>"
    end

    output.join
  end
end

class CachedFlickrSet < FlickrSet
	extend ActiveSupport::Memoizable
	memoize :render
end

# This example was crafted by @mklnz
# See: http://emberfy.com/blog/2013/02/16/octopress-plus-flickr/ for more info.
class FlickrImage < Liquid::Tag
  def initialize(tag_name, markup, tokens)
     super
     @markup = markup
     @id   = markup.split(" ")[0]
     @size = markup.split(" ")[1]
     @desc = markup.split(" ")[2]
     @meta = markup.split(" ")[3]
  end

  def render(context)
    FlickRaw.api_key        = ENV["FLICKR_KEY"]
    FlickRaw.shared_secret  = ENV["FLICKR_SECRET"]

    output = []

    # Basic info
    info = flickr.photos.getInfo(photo_id: @id)

    title         = info["title"]
    description   = info["description"]

    src           = FlickRaw.send("url_#{@size}", info)
    page_url      = FlickRaw.url_photopage(info)

    img_tag       = "<img src=\"#{src}\" title=\"#{title}\"/>"
    output[0]     = "<a href=\"#{page_url}\">#{img_tag}</a>"

    output[1]     = "<p>#{description}</p>" if @desc == "y"

    if @meta == "y"
      # EXIF
      exif          = flickr.photos.getExif(photo_id: @id)
      camera        = exif["camera"]

      f_number, exposure_time, iso, focal_length = ""

      exif["exif"].each do |exif_line|
        f_number =  exif_line["clean"] if exif_line["tag"] == "FNumber"
        exposure_time = exif_line["clean"] if exif_line["tag"] == "ExposureTime"
        iso = exif_line["raw"] if exif_line["tag"] == "ISO"
        focal_length = exif_line["clean"] if exif_line["tag"] == "FocalLength"
      end

      exif_table = "<table class=\"flickr-exif\">
        <tr>
          <td>Camera</td>
          <td>#{camera}</td>
        </tr>
        <tr>
          <td>Exposure</td>
          <td>#{exposure_time}</td>
        </tr>
        <tr>
          <td>Aperture</td>
          <td>#{f_number}</td>
        </tr>
        <tr>
          <td>Focal Length</td>
          <td>#{focal_length}</td>
        </tr>
        <tr>
          <td>ISO</td>
          <td>#{iso}</td>
        </tr>
      </table>".gsub("\n", "")

      output[2] = exif_table
    end

    # Build output
    output.join
  end
end

Liquid::Template.register_tag("flickr_image", FlickrImage)
Liquid::Template.register_tag("flickr_setlist", FlickrSet)
Liquid::Template.register_tag("flickr_cached_setlist", CachedFlickrSet)
