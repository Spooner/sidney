# encoding: utf-8

require_relative 'json_serialization_wrapper'
require_relative 'visual_resource'
require_relative 'room'
require_relative 'state_object_layer'
require_relative 'pack'

module Sidney
  class Scene < VisualResource  
    belongs_to :room

    has_many :state_object_layers
    has_many :state_objects, through: :state_object_layers
    has_and_belongs_to_many :packs

    # Manage saving tint (Gosu::Color) as json.
    before_save JsonSerializationWrapper.new(:tint)
    after_save  JsonSerializationWrapper.new(:tint)
    after_find  JsonSerializationWrapper.new(:tint)

    after_create :link_to_packs

    CURRENT_VERSION = 2
    DEFAULT_OBJECT_ZERO_FROZEN = false
    DEFAULT_TINT = Color.rgba(0, 0, 0, 0)
    SAVE_ZOOM = 1 # Render to a image this many times larger.

    THUMBNAIL_SIZE = 64

    def thumbnail_size; THUMBNAIL_SIZE; end

    def self.current_version
      CURRENT_VERSION
    end

    public
    def composed_image?; true; end

    protected
    def initialize(options)
      if options[:state_object_layers]
        @state_object_layers = options[:state_object_layers]
        options.delete(:state_object_layers)
      else
        raise ArgumentError.new
      end

      super(options)
    end

    public
    def create_or_update
      if @state_object_layers
         @state_object_layers.each do |layer|
          layer.scene_id = id
          layer.save!
        end
        @state_object_layers = nil
      end

      super
    end

    def self.attributes_from_data(data, attributes = {})
      version, offset = read_version(data)

      attributes[:room_id] = data[offset, UID_NUM_BYTES].unpack(UID_PACK)[0]
      offset += UID_NUM_BYTES


      room_alpha, object_zero_frozen, num_objects = data[offset, 3].unpack("CCC")
      offset += 3
      attributes[:tint] = Color.rgba(0, 0, 0, 255 - room_alpha)

      object_data_length = StateObjectLayer.data_length(version)

      object_layers = []
      (0...num_objects).each do |z|
        object_data = data[offset + (z * object_data_length), object_data_length]
        object_layers.push StateObjectLayer.new(nil, version, object_data, z)
      end

      # All layers have locking now, so if the player is specifically frozen (due to old version),
      # overwrite that default value.
      object_layers[0].locked = object_zero_frozen unless object_layers.empty?
      
      attributes[:state_object_layers] = object_layers
      offset += object_data_length * num_objects

      super(data[offset..-1], attributes)
    end

    def self.default_attributes(attributes = {})
      attributes[:room_id] = Room.default.id unless attributes[:room_id]
      attributes[:tint] = DEFAULT_TINT.dup unless attributes[:tint]
      attributes[:state_object_layers] = [] # TODO: create default player object.
      
      super(attributes)
    end

    # After creating, link the scene to a pack.
    def link_to_packs
      # If a scene has a prefix, put it into that pack. E.g. JPNmegacat will be put into the pack JPN.
      if pack_name = name[/^[A-Z]{2,}/]
        add_to_pack(pack_name)
      else
        add_to_pack('NOPACK') # Put in this if we couldn't find a prefix.
      end

      add_to_pack('IMPORTED') # All SiD resources are put in this pack.

      nil
    end

    # Add to a pack, by name. If the pack does not exist, create it.
    def add_to_pack(pack_name)
      # TODO: Need to calculate a better ID. But from what?
      pack_id = pack_name.downcase.tr(' ', 'x').ljust(12, "x")

      if Pack.exists?(pack_id)
        packs << Pack.find(pack_id)
      else
        pack = packs.build(name: pack_name, sprite_id: "dummysprite1")
        pack.id = pack_id
        pack.save!
      end

      nil
    end

    protected
    def to_binary
      layers = @state_object_layers ? @state_object_layers : state_object_layers.order(:z)

      data = [
        room_id,
        tint.red, tint.green, tint.blue, tint.alpha,
      ].pack("#{UID_PACK}CCCC")

      data += layers.map { |o| o.to_binary }.join

      data + super
    end

    protected
    def create_image()
      image = Image.create(Room::WIDTH, Room::HEIGHT)
      $window.render_to_image(image) { draw }
    end

    # Layers is draw order (back to front).
    public
    def cached_layers
      unless @cached_layers
        @cached_layers = state_object_layers.includes(:state_object).all
        # TODO: Properly ensure that the player floats to the top.
        @cached_layers.first.z = 999999 unless @cached_layers.empty?
        reorder_layer_cache
      end

      @cached_layers
    end

    public
    def clear_layer_cache
      @cached_layers = nil
    end

    public
    def reorder_layer_cache
      return cached_layers unless @cached_layers
      @cached_layers = @cached_layers.sort_by.with_index {|k, i| [k.y, k.locked? ? 0 : 1, k.z, i] }
    end

    public
    def draw
      # TODO: Ensure that missing assets are shown properly.
      background = room.image rescue Room.default.image
      background.draw(0, 0, Sidney::ZOrder::SCENE)

      # Draw foreground objects.
      cached_layers.each { |layer| layer.draw }

      # Overlay a filter.
      if tint.alpha > 0
        $window.current_game_state.draw_rect(0, 0, background.width, background.height, Sidney::ZOrder::SCENE_FILTER, tint)
      end

      nil
    end

    public
    def hit_object(x, y)
      cached_layers.reverse_each do |layer|
        return layer if layer.hit?(x, y)
      end

      nil
    end

    public
    def save_frame(file_name)
      image.as_devil do |devil|
        if SAVE_ZOOM > 1
          devil.resize(WIDTH * SAVE_ZOOM, HEIGHT * SAVE_ZOOM, filter: Devil::NEAREST)
        end
        devil.save(file_name)
      end
    end
  end
end