# db/seeds.rb
require 'faker'

puts "Seeding PixelCanvas database..."

# ----- Users -----
users = []
10.times do |i|
  users << User.create!(
    email: Faker::Internet.unique.email,
    username: Faker::Internet.unique.username(specifier: 5..10),
    encrypted_password: SecureRandom.hex(16),
    bio: Faker::Quote.matz,
    pixels_drawn_count: rand(0..1000),
    play_points: rand(0..500)
  )
end
puts "Created #{users.count} users."

# ----- Color Packs -----
color_packs = []
5.times do |i|
  color_packs << ColorPack.create!(
    name: "Color Pack #{i + 1}",
    colors: Array.new(10) { Faker::Color.hex_color },
    price: (i + 1) * 2.5
  )
end
puts "Created #{color_packs.count} color packs."

# ----- Purchases -----
users.each do |user|
  purchased_pack = color_packs.sample
  Purchase.create!(
    user: user,
    color_pack: purchased_pack,
    status: ["pending", "completed", "failed"].sample,
    transaction_id: SecureRandom.uuid
  )
end
puts "Created purchases for users."

# ----- Groups -----
groups = []
3.times do |i|
  owner = users.sample
  groups << Group.create!(
    name: Faker::Team.unique.name,
    slug: Faker::Internet.unique.slug(words: 2),
    description: Faker::Lorem.sentence(word_count: 8),
    owner: owner,
    members_count: 0,
    status: ["active", "archived"].sample,
    settings: { chat_enabled: true, max_pixels_per_day: 1000 }
  )
end
puts "Created #{groups.count} groups."

# ----- Group Memberships -----
groups.each do |group|
  members = users.sample(rand(2..users.size))
  members.each do |member|
    GroupMembership.create!(
      user: member,
      group: group,
      role: ["member", "moderator"].sample,
      status: "active",
      joined_at: Faker::Time.backward(days: 30),
      notifications_enabled: [true, false].sample,
      preferences: { theme: ["dark", "light"].sample },
      pixels_drawn: rand(0..500),
      messages_sent: rand(0..100)
    )
  end
  group.update!(members_count: group.group_memberships.count)
end
puts "Created group memberships."

# ----- Pixels -----
1000.times do
  user = users.sample
  Pixel.create!(
    x: rand(0..99),
    y: rand(0..99),
    color: Faker::Color.hex_color,
    user: user,
    group: groups.sample
  )
end
puts "Created 1000 pixels."

# ----- Chat Messages -----
50.times do
  ChatMessage.create!(
    user: users.sample,
    group: groups.sample,
    content: Faker::Lorem.sentence(word_count: rand(5..12))
  )
end
puts "Created 50 chat messages."

puts "Seeding completed successfully!"
