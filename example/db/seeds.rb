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

# Create an admin user (STI)
admin = Admin.create!(
  email: "admin@example.com",
  phone: "+1987654321"
)
admin.password = "AdminSecure123"
admin.save!
admin.update!(email_confirmed_at: Time.current)
puts "  Created admin: admin@example.com (password: AdminSecure123)"

puts "Done."
