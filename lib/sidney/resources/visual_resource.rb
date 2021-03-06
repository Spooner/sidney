# encoding: utf-8

require_relative 'resource'
require_relative '../gosu_ext'

module Sidney
class VisualResource < Resource
    @abstract_class = true

    OUTLINE_COLOR = Color.rgb(200, 200, 0) # Outline in yellow.

    # Folder for storing data images.
    IMAGE_DIR = File.join(RESOURCE_DIR, 'images')

    # Folder for storing cached (composed) images.
    IMAGE_CACHE_DIR = File.join(CACHE_DIR, 'images')
    FileUtils.mkdir_p IMAGE_CACHE_DIR
    @@cached_images = Hash.new

    THUMBNAIL_CACHE_DIR = File.join(CACHE_DIR, 'thumbnails')
    FileUtils.mkdir_p THUMBNAIL_CACHE_DIR
    THUMBNAIL_SIZE = 32
    @@cached_thumbnails = Hash.new

    OUTLINE_CACHE_DIR = File.join(CACHE_DIR, 'outlines')
    FileUtils.mkdir_p OUTLINE_CACHE_DIR
    @@cached_outlines = Hash.new

    IMAGE_EXTENSION = 'png'

    def thumbnail_size; THUMBNAIL_SIZE; end

    # Does the resource need to cache an outline?
    public
    def has_outline?; false; end

    # Is the image composed of other images (so it can be cached)?
    public
    def composed_image?; false; end

    public
    def image_path
      dir = composed_image? ? IMAGE_CACHE_DIR : IMAGE_DIR
      File.join(dir, type, "#{id}.#{IMAGE_EXTENSION}")
    end

    public
    def thumbnail_path
      File.join(THUMBNAIL_CACHE_DIR, type, "#{id}.#{IMAGE_EXTENSION}")
    end

    public
    def outline_path
      File.join(OUTLINE_CACHE_DIR, type, "#{id}.#{IMAGE_EXTENSION}")
    end

    public
    def load_image
      file_name = image_path
      if File.exists? file_name
        Image.new($window, file_name, false, caching: true)
      else
        nil
      end
    end

    public
    def load_thumbnail
      file_name = thumbnail_path
      if File.exists? file_name
        Image.new($window, file_name)
      else
        nil
      end
    end

    public
    def load_outline
      file_name = outline_path
      if File.exists? file_name
        Image.new($window, file_name)
      else
        nil
      end
    end

    # Caches the image and thumbnail onto the disk.
    public
    def cache_image(image)
      FileUtils.mkdir_p File.dirname(image_path)
      @@cached_images[id] = image
      image.save(image_path)

      FileUtils.mkdir_p File.dirname(thumbnail_path)
      @@cached_thumbnails[id] = make_thumbnail(image)
      @@cached_thumbnails[id].save(thumbnail_path)

      if has_outline?
        FileUtils.mkdir_p File.dirname(outline_path)
        @@cached_outlines[id] = @@cached_images[id].outline
        @@cached_outlines[id].save(outline_path)
      end

      @@cached_images[id]
    end

    public
    def make_thumbnail(image)
      image.as_devil do |devil|
        # Make it into a thumb
        filter = if devil.width > thumbnail_size or devil.height > thumbnail_size
          Devil::SCALE_LANCZOS3 # Blurry.
        else
          Devil::NEAREST # Pixelly.
        end
        devil.thumbnail(thumbnail_size, filter: filter)

        devil.to_gosu($window)
      end
    end

    public
    def image
      @@cached_images[id] ||= load_image || cache_image(create_image)
    end

    public
    def thumbnail
      unless @@cached_thumbnails[id]
        cache_image(image) unless @@cached_thumbnails[id] = load_thumbnail
      end

      @@cached_thumbnails[id]
    end

    public
    def outline
      if has_outline?
        unless @@cached_outlines[id]
          cache_image(image) unless @@cached_outlines[id] = load_outline
        end

        @@cached_outlines[id]
      else
        raise "#{self.class} does not have an outline"
      end
    end

    # Force any cached images to be re-drawn.
    public
    def redraw
      File.delete image_path if File.exists? image_path
      @@cached_images.delete id
      File.delete thumbnail_path if File.exists? thumbnail_path
      @@cached_thumbnails.delete id

      if has_outline?
        File.delete outline_path if File.exists? outline_path
        @@cached_outlines.delete id
      end

      image # Force redraw now, in update, not in draw later.
    end
  end
end