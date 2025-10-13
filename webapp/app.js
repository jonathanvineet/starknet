// Starknet Web Wallet Integration
class StarknetWalletApp {
    constructor() {
        this.wallet = null;
        this.isConnected = false;
        this.userAddress = null;
        this.provider = null;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.checkExistingConnection();
    }

    setupEventListeners() {
        // Wallet connection buttons
        document.getElementById('braavos-btn').addEventListener('click', () => this.connectBraavos());
        document.getElementById('argent-btn').addEventListener('click', () => this.connectArgent());
        document.getElementById('browser-btn').addEventListener('click', () => this.connectBrowser());
    }

    async checkExistingConnection() {
        try {
            // Check if get-starknet is available
            if (typeof window.starknet !== 'undefined') {
                const lastWallet = localStorage.getItem('lastConnectedWallet');
                if (lastWallet) {
                    await this.connectWallet(lastWallet);
                }
            }
        } catch (error) {
            console.log('No existing connection found');
        }
    }

    showStatus(message, type = 'loading') {
        const statusEl = document.getElementById('status');
        statusEl.className = `status ${type}`;
        statusEl.textContent = message;
        statusEl.classList.remove('hidden');
        
        // Auto-hide success/error messages after 5 seconds
        if (type !== 'loading') {
            setTimeout(() => {
                statusEl.classList.add('hidden');
            }, 5000);
        }
    }

    async connectBraavos() {
        this.showStatus('🦊 Connecting to Braavos wallet...', 'loading');
        await this.connectWallet('braavos');
    }

    async connectArgent() {
        this.showStatus('🛡️ Connecting to Argent X...', 'loading');
        await this.connectWallet('argentX');
    }

    async connectBrowser() {
        this.showStatus('🌐 Connecting to browser extension...', 'loading');
        
        try {
            // Try to connect to any available wallet
            const starknet = await getStarknet.getStarknet();
            if (starknet) {
                await this.connectWallet(starknet.id || 'browser');
            } else {
                throw new Error('No Starknet wallet found');
            }
        } catch (error) {
            this.showStatus('❌ No browser wallet found. Please install Braavos or Argent X extension.', 'error');
        }
    }

    async connectWallet(walletId) {
        try {
            let starknet;
            
            // Check if we're in a mobile app context
            if (window.webkit && window.webkit.messageHandlers) {
                // We're in a WKWebView - delegate to native iOS app
                this.delegateToNative('connectWallet', { walletId });
                return;
            }
            
            // Web browser context
            if (walletId === 'braavos') {
                starknet = await getStarknet.getStarknet({ 
                    filters: { provider: 'braavos' } 
                });
            } else if (walletId === 'argentX') {
                starknet = await getStarknet.getStarknet({ 
                    filters: { provider: 'argentX' } 
                });
            } else {
                starknet = await getStarknet.getStarknet();
            }

            if (!starknet) {
                throw new Error(`${walletId} wallet not found`);
            }

            // Enable the wallet
            await starknet.enable();
            
            if (starknet.isConnected) {
                this.wallet = starknet;
                this.isConnected = true;
                this.userAddress = starknet.selectedAddress;
                
                // Store the wallet preference
                localStorage.setItem('lastConnectedWallet', walletId);
                
                this.showConnectedState();
                this.showStatus('✅ Wallet connected successfully!', 'success');
                
                // Load wallet data
                await this.loadWalletData();
            } else {
                throw new Error('Failed to connect to wallet');
            }
            
        } catch (error) {
            console.error('Wallet connection error:', error);
            this.showStatus(`❌ Failed to connect: ${error.message}`, 'error');
        }
    }

    showConnectedState() {
        // Hide connection buttons
        document.querySelectorAll('.connect-button').forEach(btn => {
            btn.style.display = 'none';
        });
        
        // Show wallet info
        const walletInfo = document.getElementById('wallet-info');
        const addressEl = document.getElementById('wallet-address');
        
        walletInfo.classList.remove('hidden');
        addressEl.textContent = this.userAddress || 'Not available';
        
        // Show action buttons
        document.getElementById('action-buttons').classList.remove('hidden');
    }

    async loadWalletData() {
        try {
            if (!this.wallet) return;
            
            // Load balance, network info, etc.
            const chainId = await this.wallet.request({
                type: 'wallet_requestChainId'
            });
            
            document.getElementById('network-info').textContent = 
                chainId === '0x534e5f5345504f4c4941' ? 'Starknet Sepolia' : 'Starknet Mainnet';
                
        } catch (error) {
            console.error('Error loading wallet data:', error);
        }
    }

    delegateToNative(action, data) {
        try {
            // Send message to iOS app
            window.webkit.messageHandlers.starknetBridge.postMessage({
                action: action,
                data: data
            });
        } catch (error) {
            console.error('Failed to delegate to native app:', error);
            this.showStatus('❌ Native app communication failed', 'error');
        }
    }

    disconnect() {
        this.wallet = null;
        this.isConnected = false;
        this.userAddress = null;
        
        // Clear stored wallet
        localStorage.removeItem('lastConnectedWallet');
        
        // Reset UI
        document.querySelectorAll('.connect-button').forEach(btn => {
            btn.style.display = 'flex';
        });
        
        document.getElementById('wallet-info').classList.add('hidden');
        document.getElementById('action-buttons').classList.add('hidden');
        document.getElementById('qr-section').classList.add('hidden');
        
        this.showStatus('🔌 Wallet disconnected', 'success');
    }

    // QR Scanner functionality
    async startQRScanner() {
        try {
            const video = document.getElementById('video');
            const canvas = document.getElementById('canvas');
            const ctx = canvas.getContext('2d');
            
            // Request camera access
            const stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: 'environment' }
            });
            
            video.srcObject = stream;
            video.hidden = false;
            video.play();
            
            // Start scanning
            const scanFrame = () => {
                if (video.readyState === video.HAVE_ENOUGH_DATA) {
                    canvas.width = video.videoWidth;
                    canvas.height = video.videoHeight;
                    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
                    
                    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
                    const code = jsQR(imageData.data, imageData.width, imageData.height);
                    
                    if (code) {
                        this.handleQRCode(code.data);
                        video.srcObject.getTracks().forEach(track => track.stop());
                        video.hidden = true;
                        return;
                    }
                }
                requestAnimationFrame(scanFrame);
            };
            
            requestAnimationFrame(scanFrame);
            
        } catch (error) {
            console.error('QR Scanner error:', error);
            this.showStatus('❌ Camera access denied or not available', 'error');
        }
    }

    handleQRCode(data) {
        this.showStatus(`📱 QR Code detected: ${data}`, 'success');
        
        // Process the QR code data
        if (data.startsWith('starknet:')) {
            this.processPaymentQR(data);
        } else {
            // Generic QR code handling
            console.log('QR Code data:', data);
        }
    }

    async processPaymentQR(qrData) {
        try {
            // Parse Starknet payment QR code
            const url = new URL(qrData);
            const address = url.pathname;
            const amount = url.searchParams.get('amount');
            const token = url.searchParams.get('token') || 'ETH';
            
            this.showStatus(`💳 Processing payment: ${amount} ${token} to ${address.slice(0, 10)}...`, 'loading');
            
            // Delegate to native app for transaction processing
            if (window.webkit && window.webkit.messageHandlers) {
                this.delegateToNative('processPayment', {
                    address,
                    amount,
                    token
                });
            } else {
                // Web-based transaction (if wallet supports it)
                await this.sendTransaction(address, amount, token);
            }
            
        } catch (error) {
            console.error('Payment processing error:', error);
            this.showStatus('❌ Failed to process payment', 'error');
        }
    }

    async sendTransaction(to, amount, token) {
        if (!this.wallet) {
            throw new Error('Wallet not connected');
        }
        
        // Implementation would depend on the specific transaction requirements
        // This is a placeholder for actual transaction logic
        console.log('Sending transaction:', { to, amount, token });
    }
}

// Utility functions for native app integration
window.showVaultActions = function() {
    if (window.webkit && window.webkit.messageHandlers) {
        window.webkit.messageHandlers.starknetBridge.postMessage({
            action: 'showVaultActions',
            data: {}
        });
    } else {
        alert('Vault actions - redirect to native functionality');
    }
};

window.showQRScanner = function() {
    document.getElementById('qr-section').classList.toggle('hidden');
};

window.showPayments = function() {
    if (window.webkit && window.webkit.messageHandlers) {
        window.webkit.messageHandlers.starknetBridge.postMessage({
            action: 'showPayments',
            data: {}
        });
    } else {
        alert('Payments - redirect to native functionality');
    }
};

window.disconnect = function() {
    window.starknetApp.disconnect();
};

// Initialize the app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.starknetApp = new StarknetWalletApp();
    
    // Register service worker for PWA functionality
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('sw.js').catch(console.error);
    }
});