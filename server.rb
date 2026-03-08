require 'stripe'
require 'sinatra'

# This test secret API key is a placeholder. Don't include personal details in requests with this key.
# To see your test secret API key embedded in code samples, sign in to your Stripe account.
# You can also find your test secret API key at https://dashboard.stripe.com/test/apikeys.
Stripe.api_key = ENV['STRIPE_SECRET_KEY']

$inventory = 100
$total_sold = 0
$orders = []

set :static, true
set :port, 4242

YOUR_DOMAIN = 'http://localhost:4242'

post '/create-checkout-session' do
  if $inventory <= 0
    halt 400, "Error: We are officially sold out of books!"
  end

  content_type 'application/json'

  session = Stripe::Checkout::Session.create({
    line_items: [{
      # Provide the exact Price ID (for example, price_1234) of the product you want to sell
      price: 'price_1T893SGxud3NKxokZ7AiEsw7',
      quantity: 1,
      adjustable_quantity: {
        enabled: true,
        minimum: 1,
        maximum: $inventory,
      },
    }],
    mode: 'payment',
    success_url: YOUR_DOMAIN + '/success.html?session_id={CHECKOUT_SESSION_ID}',
    cancel_url: YOUR_DOMAIN + '/cancel.html',
  })

  $orders << {
    id: session.id,
    customer: { name: "Pending...", email: "Pending..." }, 
    session: { 
      payment_status: "pending", 
      currency: "usd", 
      amount_total: 0
    }
  }

  $inventory -= 1
  $total_sold += 1

  puts "Book sold! Inventory left: #{$inventory}. Total sold: #{$total_sold}"
  
  redirect session.url, 303
end

get '/order-info' do
  content_type 'application/json'
  session_id = params[:session_id]
  session = Stripe::Checkout::Session.retrieve({
    id: session_id,
    expand: ['line_items']
  })

  order = $orders.find { |o| o[:id] == session_id }
  if order
    actual_qty = session.line_items.data[0].quantity

    extra_books = actual_qty - 1
    $inventory -= extra_books
    $total_sold += extra_books

    order[:customer][:name] = session.customer_details.name
    order[:customer][:email] = session.customer_details.email
    order[:session][:payment_status] = session.payment_status
    order[:session][:amount_total] = session.amount_total
  end
  
  # Retrieve the customer
  {
    customer: {
      name: session.customer_details.name,
      email: session.customer_details.email
    },
    session: {
      payment_status: session.payment_status,
      currency: session.currency,
      amount_total: session.amount_total
    }
  }.to_json
end

# 4. New route to view the line-by-line report
get '/admin/orders' do
  content_type 'text/html'
  
  # Create table rows dynamically
  rows = $orders.map do |order|
    "<tr>
      <td>#{order[:customer][:name]}</td>
      <td>#{order[:customer][:email]}</td>
      <td>#{(order[:session][:amount_total] / 100.0).round(2)} #{order[:session][:currency].upcase}</td>
      <td>#{order[:session][:payment_status]}</td>
    </tr>"
  end.join

  # HTML wrapper
  "<html>
    <head><title>Order Report</title></head>
    <body style='font-family: sans-serif; padding: 40px;'>
      <h1>Sales Report</h1>
      <p><strong>Total Sold:</strong> #{$total_sold} | <strong>Inventory Left:</strong> #{$inventory}</p>
      <table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%;'>
        <thead>
          <tr style='background: #f4f4f4;'>
            <th>Customer Name</th>
            <th>Email</th>
            <th>Amount</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          #{rows.empty? ? '<tr><td colspan="4">No orders yet.</td></tr>' : rows}
        </tbody>
      </table>
      <br>
    </body>
  </html>"
end