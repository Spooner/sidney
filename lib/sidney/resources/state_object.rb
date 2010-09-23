require_relative 'visual_resource'

require_relative 'sprite_layer'

module RSiD
  class StateObject < VisualResource   
    has_many :sprite_layers
    has_many :sprites, through: :sprite_layers

    has_many :object_layers
    has_many :scenes, through: :object_layers
    
    WIDTH = Sprite::WIDTH * 13
    HEIGHT = Sprite::HEIGHT * 13

    CURRENT_VERSION = 3

    def num_layers
      StateObjectLayer.where(state_object_uid: uid).count
    end

    def self.current_version
      CURRENT_VERSION
    end

    def initialize(options)
      if options[:version] and options[:layer_data]
        @version = options[:version]
        options.delete(:version)
        @layer_data = options[:layer_data]
        options.delete(:layer_data)
      else
        raise ArgumentError.new
      end

      super(options)
    end
    
    def self.attributes_from_data(data, attributes = {})
      version, offset = read_version(data)
      attributes[:version] = version

      num_layers = data[offset, 1].unpack("C")[0]
      offset += 1

      layer_size = SpriteLayer.data_size(version)

      attributes[:layer_data] = data[offset, num_layers * layer_size]
      offset += num_layers * layer_size

      super(data[offset..-1], attributes)
    end

    def self.default_attributes(attributes = {})
      attributes[:version] = CURRENT_VERSION
      attributes[:layer_data] = ''

      super(attributes)
    end

    def create_or_update
      if @version and @layer_data
        layer_size = SpriteLayer.data_size(@version)
        (0...@layer_data.size).step(layer_size) do |offset|
          layer = SpriteLayer.new(uid, @version, @layer_data[offset, layer_size])
          layer.save!
        end
        @version = @layer_data = nil
      end
      
      super
    end

    def to_binary
      data = [
        MAGIC_CODE,
        CURRENT_VERSION,
      ].pack("a*C")

      if @layer_data
        # TODO: Won't work for old versions
        #raise Exception.new if @version < CURRENT_VERSION
        layer_size = SpriteLayer.data_size(@version)
        data += [@layer_data.length / layer_size].pack("C")
        data += @layer_data
      else
        layers = SpriteLayer.where(state_object_uid: uid)
        data += [layers.count].pack("C")
        data += layers.map { |layer| layer.to_binary }.join
      end

      data + super
    end

    def create_image
      unless img = super
        img = Image.create(WIDTH, HEIGHT)

        layers = SpriteLayer.where(state_object_uid: uid)
        layers.each { |layer| layer.draw_on_image(img, Sprite::WIDTH * 6, Sprite::HEIGHT * 5) }
        box = img.auto_crop_box
        img = img.crop box
        img.save(File.join(IMAGE_CACHE_DIR, "#{uid}.png"))
      end

      img
    end

    def draw_on_image(canvas, offset_x, offset_y, opacity)
      color_proc = if opacity < 255
        opacity /= 255.0
        lambda { |c| c[3] = opacity unless c[3] == 0; c }
      else
        nil
      end

      canvas.splice(image, offset_x - Sprite::WIDTH * 6, offset_y - Sprite::HEIGHT * 5,
                    alpha_blend: true, color_control: color_proc)
    end
  end
end