# frozen_string_literal: true

require 'spec_helper'

describe 'Stripe Elements 3ds checkout', type: :feature, js: true do
  let!(:product) { create(:product, name: 'RoR Mug') }
  let!(:stripe_payment_method) do
    Spree::Gateway::StripeElementsGateway.create!(
        name: 'Stripe',
        preferred_secret_key: 'sk_test_VCZnDv3GLU15TRvn8i2EsaAN',
        preferred_publishable_key: 'pk_test_Cuf0PNtiAkkMpTVC2gwYDMIg',
        preferred_intents: preferred_intents,
        stores: [::Spree::Store.default]
    )
  end

  before do
    user = create(:user)
    order = OrderWalkthrough.up_to(:confirm)
    expect(order).to receive(:confirmation_required?).and_return(true).at_least(:once)

    order.reload
    order.user = user
    payment = order.payments.first
    payment.source = create(:credit_card, number: card_number)
    payment.save!

    allow_any_instance_of(Spree::CheckoutController).to receive_messages(current_order: order)
    allow_any_instance_of(Spree::CheckoutController).to receive_messages(try_spree_current_user: user)
    allow_any_instance_of(Spree::CheckoutController).to receive_messages(skip_state_validation?: true)
    allow_any_instance_of(Spree::OrdersController).to receive_messages(try_spree_current_user: user)

    add_to_cart(product)

    if Spree.version.to_f >= 3.7 and Spree.version.to_f < 4.1
      find("#checkout-link").click
    else
      click_link 'checkout'
      click_button 'Place Order'
    end
  end

  describe 'when intents are disabled' do
    let(:preferred_intents) { false }

    context 'and credit card does not require 3ds authentication' do
      let(:card_number) { '4242424242424242' }

      if Spree.version.to_f >= 3.7 and Spree.version.to_f < 4.1
        it 'should place order without 3ds authentication', driver: :selenium_chrome_headless do
          click_button 'Save and Continue'
          click_button 'Save and Continue'

          within_frame 0 do
            fill_in 'cardnumber', with: card_number
            fill_in 'exp-date', with: "01 / #{Time.current.strftime('%y').to_i + 3}"
            fill_in 'cvc', with: "222"
          end

          click_button 'Save and Continue'
          click_button 'Place Order'

          expect(page).to have_content('Your order has been processed successfully')
          order = Spree::Order.complete.last
          expect(page.current_url).to include("/orders/#{order.number}")
          expect(page).to have_content(order.number)
        end
      else
        it 'should place order without 3ds authentication' do
          expect(page).to have_content('Order placed successfully')
          order = Spree::Order.complete.last
          expect(page.current_url).to include("/orders/#{order.number}")
          expect(page).to have_content(order.number)
        end
      end
    end

    context 'and credit card does require 3ds authentication' do
      let(:card_number) { '4000000000003220' }

      if Spree.version.to_f >= 3.7 and Spree.version.to_f < 4.1
        it 'should not place the order', driver: :selenium_chrome_headless do
          click_button 'Save and Continue'
          click_button 'Save and Continue'

          within_frame 0 do
            fill_in 'cardnumber', with: card_number
            fill_in 'exp-date', with: "01 / #{Time.current.strftime('%y').to_i + 3}"
            fill_in 'cvc', with: "222"
          end

          click_button 'Save and Continue'
          click_button 'Place Order'

          expect(page).to have_content('Your card was declined. This transaction requires authentication.')
          expect(Spree::Order.complete.last).to be_nil
        end

      else
        it 'should not place the order' do
          expect(page).to have_content('Your card was declined. This transaction requires authentication.')
          expect(Spree::Order.complete.last).to be_nil
        end
      end
    end
  end

  describe 'when intents are enabled' do
    let(:preferred_intents) { true }

    context 'and credit card does not require 3ds authentication' do
      let(:card_number) { '4242424242424242' }

      if Spree.version.to_f >= 3.7 and Spree.version.to_f < 4.1
        it 'should successfully place order without 3ds authentication', driver: :selenium_chrome_headless do
          click_button 'Save and Continue'
          click_button 'Save and Continue'

          within_frame 0 do
            fill_in 'cardnumber', with: card_number
            fill_in 'exp-date', with: "01 / #{Time.current.strftime('%y').to_i + 3}"
            fill_in 'cvc', with: "222"
          end

          click_button 'Save and Continue'
          click_button 'Place Order'

          expect(page).to have_content('Your order has been processed successfully')
          order = Spree::Order.complete.last
          expect(page.current_url).to include("/orders/#{order.number}")
          expect(page).to have_content(order.number)
        end
      else
        it 'should successfully place order without 3ds authentication' do
          expect(page).to have_content('Order placed successfully')
          order = Spree::Order.complete.last
          expect(page.current_url).to include("/orders/#{order.number}")
          expect(page).to have_content(order.number)
        end
      end
    end

    context 'when credit card does require 3ds authentication' do
      let(:card_number) { '4000000000003220' }

      context 'and authentication is successful' do
        if Spree.version.to_f >= 3.7 and Spree.version.to_f < 4.1
          it 'should place order after 3ds authentication', driver: :selenium_chrome_headless do
            click_button 'Save and Continue'
            click_button 'Save and Continue'

            within_frame 0 do
              fill_in 'cardnumber', with: card_number
              fill_in 'exp-date', with: "01 / #{Time.current.strftime('%y').to_i + 3}"
              fill_in 'cvc', with: "222"
            end

            click_button 'Save and Continue'
            click_button 'Place Order'

            within_stripe_3ds_popup do
              click_button('Complete')
            end

            expect(page).to have_content('Your order has been processed successfully')
            order = Spree::Order.complete.last
            expect(page.current_url).to include("/orders/#{order.number}")
            expect(page).to have_content(order.number)
          end

        else
          it 'should place order after 3ds authentication' do
            within_stripe_3ds_popup do
              click_button('Complete')
            end

            expect(page).to have_content('Order placed successfully')
            order = Spree::Order.complete.last
            expect(page.current_url).to include("/orders/#{order.number}")
            expect(page).to have_content(order.number)
          end
        end
      end

      context 'and authentication is unsuccessful' do

        if Spree.version.to_f >= 3.7 and Spree.version.to_f < 4.1
          it 'should not place order after 3ds authentication', driver: :selenium_chrome_headless do
            click_button 'Save and Continue'
            click_button 'Save and Continue'

            within_frame 0 do
              fill_in 'cardnumber', with: card_number
              fill_in 'exp-date', with: "01 / #{Time.current.strftime('%y').to_i + 3}"
              fill_in 'cvc', with: "222"
            end

            click_button 'Save and Continue'
            click_button 'Place Order'

            within_stripe_3ds_popup do
              click_button('Fail')
            end

            expect(page).to_not have_content('Order placed successfully')
            expect(page).to have_content('We are unable to authenticate your payment method.')
            expect(page).to have_content('Please choose a different payment method and try again.')
            expect(Spree::Order.complete.last).to be_nil
          end
        else
          it 'should not place order after 3ds authentication' do
            within_stripe_3ds_popup do
              click_button('Fail')
            end

            expect(page).to_not have_content('Order placed successfully')
            expect(page).to have_content('We are unable to authenticate your payment method.')
            expect(page).to have_content('Please choose a different payment method and try again.')
            expect(Spree::Order.complete.last).to be_nil
          end
        end
      end
    end
  end
end
