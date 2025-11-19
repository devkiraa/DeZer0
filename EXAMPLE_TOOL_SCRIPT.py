"""
LED Blink Tool - Example Script
This script demonstrates how to use pin mappings from the hardware configuration.
The app will automatically inject LED_PIN based on user's hardware configuration.
"""

# Pin mappings are injected by the app
# LED_PIN will be set to the actual GPIO pin number configured by the user
# For example: LED_PIN = 23 if user configured LED on GPIO23

try:
    # Get the LED pin from parameters (injected by app)
    led_pin = params.get('LED_PIN')
    
    if led_pin is None:
        print("Error: LED_PIN not configured. Please set up LED in Hardware Config.")
        raise SystemExit(1)
    
    print(f"Using LED on GPIO{led_pin}")
    
    # Configure the pin as output
    gpio_config(led_pin, GPIO_OUTPUT)
    
    # Blink the LED 10 times
    for i in range(10):
        print(f"Blink {i+1}/10")
        gpio_set(led_pin, 1)  # Turn LED ON
        sleep(500)  # Wait 500ms
        gpio_set(led_pin, 0)  # Turn LED OFF
        sleep(500)  # Wait 500ms
    
    print("LED blinking completed!")
    print("--- Execution Finished ---")
    
except Exception as e:
    print(f"Error: {e}")
    print("--- Execution Finished ---")
