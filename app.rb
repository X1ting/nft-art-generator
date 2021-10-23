require 'mini_magick'
require 'pry'
require 'benchmark'

DELIMITER = '_'
IMAGES_COUNT = 100
Trait = Struct.new(:position, :name, :rarity, :images)
Image = Struct.new(:file, :name, :rarity)

### Given rarity 20%
### Generate random number from 0...100
### If (100 - rarity) is in range, it success
def kawabanga?(rarity)
  (0..rand(0...100)).include?(100 - rarity)
end

def combine_images(first_image, second_image)
  first_image.composite(second_image) do |c|
    c.compose "Over"    # OverCompositeOp
    c.geometry "+0+0" # copy second_image onto first_image from (20, 20)
  end
end

def generate_image(traits)
  image = traits.reduce(nil) do |acc, trait|
    if acc.nil?
      trait.images.sample.file
    else
      new_image = trait.images.select { |image| kawabanga?(image.rarity) }.sample
      if kawabanga?(trait.rarity) && new_image
        combine_images(acc, new_image.file)
      else
        acc
      end
    end
  end
end

def images_from(dir)
  Dir[dir + "/*"].map do |image|
    image_name = image.split('/').last.split('.').first
    Image.new(
      MiniMagick::Image.new(image),
      image_name.split('_').first,
      image_name.split('_').last.to_i
    )
  end
end
measurement = Benchmark.measure do
  traits = Dir['./images/*'].map do |full_dir_name|
    next unless File.directory?(full_dir_name)
    dir_name = full_dir_name.split('/').last
    splitted = dir_name.split(DELIMITER)
    next unless splitted.first == 'trait'
    images = images_from(full_dir_name)
    Trait.new(splitted[1].to_i, splitted[2], splitted[3].to_i, images)
  end.compact.sort_by!(&:position)

  signatures = []
  valid_images = []
  IMAGES_COUNT.times do |index|
    image = generate_image(traits)
    unless signatures.include?(image.signature)
      signatures.push(image.signature)
      image.write("./output/#{index}.png")
    end
  end
end
puts measurement
puts 'Done'
