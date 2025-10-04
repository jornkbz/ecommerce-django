from django.views.decorators.csrf import ensure_csrf_cookie
#from django.views.decorators.csrf import csrf_exempt
from django.http import JsonResponse
from django.shortcuts import render, redirect
from django.contrib import messages
from carts.models import CartItem
from .forms import OrderForm
import datetime
from .models import Order, Payment, OrderProduct
import json
from store.models import Product
from django.core.mail import EmailMessage
from django.template.loader import render_to_string
#@ensure_csrf_cookie
def payments(request):
    # Opcional: solo si quieres permitir entrar directo a /orders/payments/

    body = json.loads(request.body)
    order = Order.objects.get(user=request.user, is_ordered=False, order_number=body['orderID'])

    payment = Payment(
        user = request.user,
        payment_id = body['transID'],
        payment_method = body['payment_method'],
        amount_id = order.order_total,
        status = body['status'],
    )
    payment.save()

    order.payment = payment
    order.is_ordered = True
    order.save()

    #Mover todos los carritos items hacia la tabla order product
    cart_items = CartItem.objects.filter(user=request.user)
    
    for item in cart_items:
        orderproduct = OrderProduct()
        orderproduct.order_id = order.id
        orderproduct.payment = payment
        orderproduct.user_id = request.user.id
        orderproduct.product_id = item.product_id
        orderproduct.quantity = item.quantity
        orderproduct.product_price = item.product.price
        orderproduct.ordered = True
        orderproduct.save()
        
        cart_item = CartItem.objects.get(id=item.id)
        product_variation = cart_item.variations.all()
        orderproduct = OrderProduct.objects.get(id=orderproduct.id)
        orderproduct.variation.set(product_variation)
        orderproduct.save()
        
        product = Product.objects.get(id=item.product_id)
        product.stock -= item.quantity
        product.save()
        
    CartItem.objects.filter(user=request.user).delete()
    
    mail_subject = 'Gracias por su compra'
    body = render_to_string('orders/order_recieved_email.html', {
        'user': request.user,
        'order': order,
        
    })
    
    to_email = request.user.email
    send_email = EmailMessage(mail_subject, body, to=[to_email])
    send_email.send()


    data = {
        'order_number' : order.order_number,
        'transID' : payment.payment_id,
    }
    
    return JsonResponse(data)

def place_order(request, total=0, quantity=0):
    current_user = request.user
    cart_items = CartItem.objects.filter(user=current_user)
    if not cart_items.exists():
        return redirect('store')

    # Totales
    for ci in cart_items:
        total += ci.product.price * ci.quantity
        quantity += ci.quantity
    tax = (2 * total) / 100
    grand_total = total + tax

    if request.method == 'POST':
        form = OrderForm(request.POST)
        if form.is_valid():
            data = Order()
            data.user = current_user
            data.first_name = form.cleaned_data['first_name']
            data.last_name  = form.cleaned_data['last_name']
            data.phone      = form.cleaned_data['phone']
            data.email      = form.cleaned_data['email']
            # 👇 nombres correctos
            data.addres_line_1 = form.cleaned_data['addres_line_1']
            data.addres_line_2 = form.cleaned_data.get('addres_line_2', '')
            data.country        = form.cleaned_data['country']
            data.state          = form.cleaned_data['state']
            data.city           = form.cleaned_data['city']
            data.order_note     = form.cleaned_data.get('order_note', '')
            data.order_total    = grand_total
            data.tax            = tax
            data.ip             = request.META.get('REMOTE_ADDR')
            data.save()

            # Número de pedido
            current_date = datetime.date.today().strftime("%Y%m%d")
            data.order_number = f"{current_date}{data.id}"
            data.save()

            # Pasar a pantalla de pago (estilo Udemy)
            context = {
                'order': data,
                'cart_items': cart_items,
                'total': total,
                'tax': tax,
                'grand_total': grand_total,
            }
            return render(request, 'orders/payments.html', context)
        else:
            # ❗ Imprescindible: devolver respuesta si el form es inválido ESTE ELSE SE HA MODIFICADO EN PROYECTO NO ESTA CONTEMPLADO
            messages.error(request, "Revisa los datos de facturación.")
            return render(request, 'store/checkout.html', {
                'form': form,                # para mostrar errores en plantilla
                'cart_items': cart_items,
                'total': total,
                'tax': tax,
                'grand_total': grand_total,
                'quantity': quantity,
            })

    # Si no es POST, vuelve al checkout
    return redirect('checkout')


def order_complete(request):
    
    order_number = request.GET.get('order_number')
    transID = request.GET.get('payment_id')
    
    try:
        order = Order.objects.get(order_number=order_number, is_ordered=True)
        ordered_products = OrderProduct.objects.filter(order_id=order.id)

        subtotal = 0
        for i in ordered_products:
            subtotal += i.product_price*i.quantity
            payment= Payment.objects.get(payment_id=transID)
            context = {
            'order' : order,
            'ordered_products' : ordered_products,
            'order_number': order.order_number,
            'transID' : payment.payment_id,
            'payment' : payment,
            'subtotal' : subtotal    
            }
        return render(request, 'orders/order_complete.html', context)
        
    except(Payment.DoesNotExist, Order.DoesNotExist):
        return redirect('home')


