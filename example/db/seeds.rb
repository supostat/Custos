# frozen_string_literal: true

puts "Seeding database..."

# Create a demo user
user = User.create!(
  email: "demo@example.com",
  phone: "+1234567890"
)
user.password = "password123"
user.save!
user.update!(email_confirmed_at: Time.current) # pre-confirmed
puts "  Created user: demo@example.com (password: password123)"

# Create an API client
client = ApiClient.create!(
  name: "Demo API Client",
  email: "api@example.com"
)
token = client.generate_api_token
puts "  Created API client: #{client.name}"
puts "  API token: #{token}"

puts "Done."
