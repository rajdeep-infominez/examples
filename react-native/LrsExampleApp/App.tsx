/**
 * Sample GlomoPay LRS Checkout React Native App
 *
 * https://www.npmjs.com/package/@glomopay/react-native-sdk?activeTab=readme
 * https://github.com/facebook/react-native
 */

import { useRef, useState } from 'react';
import {
    Alert,
    StatusBar,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    useColorScheme,
    View,
} from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
    GlomoLrsCheckoutRef,
    GlomoLrsCheckout,
} from '@glomopay/react-native-sdk';

function App() {
    const isDarkMode = useColorScheme() === 'dark';

    return (
        <SafeAreaProvider>
            <StatusBar
                barStyle={isDarkMode ? 'light-content' : 'dark-content'}
            />
            <AppContent />
        </SafeAreaProvider>
    );
}

function AppContent() {
    // LRS Order created for an LRS Quotation
    const [orderId, setOrderId] = useState('');

    // Your Public Key from GlomoPay Dashboard
    const [publicKey, setPublicKey] = useState('');
    const checkoutRef = useRef<GlomoLrsCheckoutRef>(null);

    const handleStartCheckout = () => {
        const started = checkoutRef.current?.start();
        if (started) {
            console.log('Started LRS Checkout');
        }
        // Validation errors should be handled via onSdkError callback
        else {
            const status = checkoutRef.current?.getStatus();
            console.log(
                'Checkout could not be started. Current status:',
                status,
            );
            Alert.alert(
                'LRS Checkout Failed',
                `Could not start LRS checkout. Current status: ${status}`,
            );
        }
    };

    return (
        <View style={styles.container}>
            <Text style={styles.title}>GlomoPay LRS Checkout Example</Text>

            <Text style={styles.info}>
                {publicKey.toLowerCase().startsWith('live_')
                    ? 'Live mode'
                    : 'Sandbox mode'}
            </Text>

            <TextInput
                style={styles.input}
                placeholder="Enter ORDER_ID"
                value={orderId}
                onChangeText={setOrderId}
                autoCapitalize="none"
                autoCorrect={false}
                placeholderTextColor="#999"
            />
            <Text style={styles.info}>
                Entered Order ID: {orderId.length > 0 ? orderId : 'empty'}
            </Text>

            <TextInput
                style={styles.input}
                placeholder="Enter Public Key"
                value={publicKey}
                onChangeText={setPublicKey}
                autoCapitalize="none"
                autoCorrect={false}
                placeholderTextColor="#999"
            />
            <Text style={styles.info}>
                Entered Public Key: {publicKey.length > 0 ? publicKey : 'empty'}
            </Text>

            {orderId.length > 0 ? (
                <TouchableOpacity
                    style={styles.button}
                    onPress={handleStartCheckout}
                >
                    <Text style={styles.buttonText}>Start LRS Checkout</Text>
                </TouchableOpacity>
            ) : (
                <Text style={styles.info}>
                    Please enter an LRS order ID to continue
                </Text>
            )}

            {
                /**
                 * Instead of conditional rendering,
                 * you can also always render the GlomoLrsCheckout component
                 * 
                 * The checkout modal will only appear after a successful call to start() method
                 */
            }

            {orderId.length > 0 && (
                <GlomoLrsCheckout
                    ref={checkoutRef}
                    publicKey={publicKey}
                    orderId={orderId}
                    onPaymentSuccess={payload => {
                        console.log('LRS Checkout successful!', payload);
                        Alert.alert(
                            'LRS Payment Successful',
                            JSON.stringify(payload),
                        );
                        setOrderId('');
                    }}
                    onPaymentFailure={payload => {
                        console.log('LRS Checkout failed!', payload);
                        Alert.alert(
                            'LRS Payment Failed',
                            JSON.stringify(payload),
                        );
                    }}
                    onConnectionError={() => {
                        console.log('Connection failure!');
                        Alert.alert(
                            'Connection Error',
                            'Failed to connect to LRS checkout URL.',
                        );
                    }}
                    onPaymentTerminate={() => {
                        Alert.alert(
                            'LRS Payment Cancelled',
                            'LRS payment was cancelled by the user.',
                        );
                        console.log('LRS Checkout terminated!');
                    }}
                    onSdkError={errors => {
                        errors.forEach(error => {
                            console.error(
                                `SDK Error [${error.type}]:`,
                                error.message,
                            );
                            if (error.field) {
                                console.error(`Field: ${error.field}`);
                            }
                        });
                        Alert.alert(
                            'SDK Error',
                            errors.map(e => e.message).join('\n'),
                        );
                    }}
                />
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: 'white',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
    },
    title: {
        fontSize: 24,
        fontWeight: 'bold',
        marginBottom: 30,
        color: '#333',
    },
    info: {
        padding: 20,
        fontSize: 12,
        color: '#666',
    },
    input: {
        width: '100%',
        borderColor: '#ccc',
        borderWidth: 1,
        borderRadius: 8,
        padding: 15,
        backgroundColor: 'white',
        fontSize: 16,
        color: 'black',
    },
    button: {
        backgroundColor: '#007AFF',
        paddingHorizontal: 40,
        paddingVertical: 15,
        borderRadius: 10,
        marginTop: 20,
        elevation: 3,
        shadowColor: 'black',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.25,
        shadowRadius: 3.84,
    },
    buttonText: {
        color: 'white',
        fontSize: 18,
        fontWeight: '600',
        textAlign: 'center',
    },
    switchContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        marginTop: 20,
        marginBottom: 10,
        gap: 10,
    },
    switchLabel: {
        fontSize: 16,
        color: '#999',
        fontWeight: '500',
    },
    activeLabelText: {
        color: '#333',
        fontWeight: '700',
    },
});

export default App;
