# Running Michael's book store

1. Build the server
   
```bash
npm install
```

2. Run the server
   
```bash
npm start
```
3. For the book store go to http://localhost:4242/checkout.html

4. Click the checkout button to be redirected to the Stripe Checkout page.

5. If 100 books have already been bought, the user will be given an error and told that the book is out of stock.

6. If there is inventory, the user can select the quanitity and enter their name, email, card, and address. (Use test card 4242424242424242 to simulate succesful payment)

7. If the payment succeeds, the user will be redirected to http://localhost:4242/success.html and the inventory will be updated.

8. If the user clicks the back button, they will be redirected to http://localhost:4242/cancel.html

9. For a report of all the orders and inventory go to http://localhost:4242/admin/orders
