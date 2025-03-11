// Initialize when the DOM is fully loaded
document.addEventListener('DOMContentLoaded', () => {
    // Global variables
    const testResults = {
        websiteTests: [],
        appTests: [],
        networkInfo: {
            publicIp: null,
            ipConfig: null,
            ping: null,
            tracert: null,
            wlanInfo: null
        },
        config: {
            changeNumber: '',
            connectionType: '',
            testDate: new Date().toISOString(),
            username: getUserInfo().username,
            hostname: getUserInfo().hostname
        },
        comments: ''
    };

    // Initialize application
    init();

    // Setup event listeners
    setupEventListeners();

    // Helper Functions
    function init() {
        // Set date time display
        document.getElementById('dateTimeDisplay').textContent = formatDate(new Date());
        
        // Display user info
        const userInfo = getUserInfo();
        document.getElementById('userInfo').textContent = `User: ${userInfo.username} | Computer: ${userInfo.hostname}`;
    }

    function getUserInfo() {
        // In a browser environment, we don't have direct access to system username and hostname
        // We'll attempt to get some info from the browser, or use placeholders
        let username = 'Unknown User';
        let hostname = 'Unknown Host';
        
        // Try to get username from localStorage if previously stored
        if (localStorage.getItem('uat_username')) {
            username = localStorage.getItem('uat_username');
        } else {
            // Prompt for username if not stored
            const promptedUsername = prompt("Please enter your username:", "");
            if (promptedUsername) {
                username = promptedUsername;
                localStorage.setItem('uat_username', username);
            }
        }
        
        return { username, hostname };
    }

    function formatDate(date) {
        return date.toISOString().replace('T', ' ').substr(0, 19);
    }

    function setupEventListeners() {
        // Configuration Section
        document.getElementById('startTestBtn').addEventListener('click', startTest);

        // Website Tests Section
        document.querySelectorAll('.test-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const testItem = this.closest('.test-item');
                const url = testItem.dataset.url;
                testWebsite(url, testItem);
            });
        });

        document.querySelectorAll('.open-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const url = this.closest('.test-item').dataset.url;
                window.open(url, '_blank');
            });
        });

        document.getElementById('getPublicIpBtn').addEventListener('click', getPublicIp);
        document.getElementById('websiteTestsNextBtn').addEventListener('click', () => {
            setActiveStep(3);
            showSection('networkInfoSection');
        });

        // Network Info Section
        document.getElementById('getIpConfigBtn').addEventListener('click', getIpConfig);
        document.getElementById('pingBtn').addEventListener('click', performPing);
        document.getElementById('tracertBtn').addEventListener('click', performTracert);
        document.getElementById('getWlanInfoBtn').addEventListener('click', getWlanInfo);
        document.getElementById('networkInfoNextBtn').addEventListener('click', () => {
            setActiveStep(4);
            showSection('appTestsSection');
        });

        // Application Tests Section
        document.querySelectorAll('.manual-test-success-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const testItem = this.closest('.test-item');
                handleManualTestResult(testItem, 'success');
            });
        });

        document.querySelectorAll('.manual-test-fail-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const testItem = this.closest('.test-item');
                handleManualTestResult(testItem, 'failure');
            });
        });

        document.querySelectorAll('.manual-test-skip-btn').forEach(btn => {
            btn.addEventListener('click', function() {
                const testItem = this.closest('.test-item');
                handleManualTestResult(testItem, 'skipped');
            });
        });

        document.getElementById('appTestsNextBtn').addEventListener('click', () => {
            setActiveStep(5);
            generateResults();
            showSection('resultsSection');
        });

        // Results Section
        document.querySelectorAll('.tab').forEach(tab => {
            tab.addEventListener('click', function() {
                const tabId = this.dataset.tab;
                activateTab(tabId);
            });
        });

        document.getElementById('saveReportBtn').addEventListener('click', saveReport);
        document.getElementById('newTestBtn').addEventListener('click', resetAndStartOver);
        
        // User comments
        document.getElementById('userComments').addEventListener('change', function() {
            testResults.comments = this.value;
        });
    }

    // Core Functions
    function startTest() {
        const changeNumber = document.getElementById('changeNumber').value.trim();
        const connectionType = document.getElementById('connectionType').value;
        
        if (!changeNumber) {
            showFlashMessage('Please enter a Change Number/ID', 'error');
            return;
        }
        
        if (!connectionType) {
            showFlashMessage('Please select a Connection Type', 'error');
            return;
        }
        
        // Store the configuration
        testResults.config.changeNumber = changeNumber;
        testResults.config.connectionType = connectionType;
        
        // Show the progress bar
        document.getElementById('testProgress').classList.remove('hidden');
        document.getElementById('configSection').classList.add('hidden');
        
        // Update progress steps
        setActiveStep(2);
        
        // Display the connection type
        document.getElementById('connectionTypeDisplay').textContent = connectionType;
        
        // Show website tests section
        showSection('websiteTestsSection');
    }

    async function testWebsite(url, testItem) {
        // Visual feedback
        const indicator = testItem.querySelector('.status-indicator');
        indicator.style.backgroundColor = '#ffc107'; // Yellow during testing

        try {
            // In a real implementation, you'd use a server-side proxy to check the URL
            // For demo purposes, we'll simulate a successful response most of the time
            await new Promise(resolve => setTimeout(resolve, 1000)); // Simulate network delay
            
            // Random success (90% success rate)
            const success = Math.random() > 0.1;
            
            if (success) {
                indicator.className = 'status-indicator success';
                
                // Record the result
                testResults.websiteTests.push({
                    name: testItem.querySelector('strong').textContent,
                    url: url,
                    status: 'success',
                    statusCode: 200,
                    notes: 'Site is accessible'
                });

                showFlashMessage(`Successfully connected to ${url}`, 'success');
            } else {
                indicator.className = 'status-indicator failure';
                
                // Record the result
                testResults.websiteTests.push({
                    name: testItem.querySelector('strong').textContent,
                    url: url,
                    status: 'failure',
                    statusCode: 500,
                    notes: 'Connection failed'
                });

                showFlashMessage(`Failed to connect to ${url}`, 'error');
            }

        } catch (error) {
            indicator.className = 'status-indicator failure';
            
            // Record the result
            testResults.websiteTests.push({
                name: testItem.querySelector('strong').textContent,
                url: url,
                status: 'failure',
                statusCode: 0,
                notes: `Error: ${error.message}`
            });

            showFlashMessage(`Error testing ${url}: ${error.message}`, 'error');
        }
    }

    async function getPublicIp() {
        const publicIpInfo = document.getElementById('publicIpInfo');
        publicIpInfo.textContent = 'Loading IP information...';
        publicIpInfo.classList.remove('hidden');
        
        try {
            // Use ipinfo.io to get public IP information
            const response = await fetch('https://ipinfo.io/json');
            const data = await response.json();
            
            // Format the output
            let output = `IP: ${data.ip}\n`;
            output += `Hostname: ${data.hostname || 'N/A'}\n`;
            output += `City: ${data.city}\n`;
            output += `Region: ${data.region}\n`;
            output += `Country: ${data.country}\n`;
            output += `Location: ${data.loc}\n`;
            output += `Organization: ${data.org}\n`;
            
            publicIpInfo.textContent = output;
            
            // Store the result
            testResults.networkInfo.publicIp = data;
            
        } catch (error) {
            publicIpInfo.textContent = `Failed to get IP information: ${error.message}`;
        }
    }

    function getIpConfig() {
        const ipConfigInfo = document.getElementById('ipConfigInfo');
        ipConfigInfo.classList.remove('hidden');
        
        // In a browser environment, we can't directly access network interfaces like ipconfig
        // We'll provide a simulated output based on browser information
        
        const output = simulateIpConfig();
        ipConfigInfo.textContent = output;
        
        // Store the result
        testResults.networkInfo.ipConfig = output;
    }

    function simulateIpConfig() {
        const connectionType = testResults.config.connectionType;
        let output = "Windows IP Configuration\n\n";
        
        if (connectionType === "LAN") {
            output += "Ethernet adapter Ethernet0:\n";
            output += "   Connection-specific DNS Suffix  . : company.local\n";
            output += "   IPv4 Address. . . . . . . . . . . : 192.168.1.100\n";
            output += "   Subnet Mask . . . . . . . . . . . : 255.255.255.0\n";
            output += "   Default Gateway . . . . . . . . . : 192.168.1.1\n\n";
        } else if (connectionType === "WLAN") {
            output += "Wireless LAN adapter Wi-Fi:\n";
            output += "   Connection-specific DNS Suffix  . : company.local\n";
            output += "   IPv4 Address. . . . . . . . . . . : 192.168.1.101\n";
            output += "   Subnet Mask . . . . . . . . . . . : 255.255.255.0\n";
            output += "   Default Gateway . . . . . . . . . : 192.168.1.1\n\n";
        } else if (connectionType === "VPN") {
            output += "PPP adapter VPN Connection:\n";
            output += "   Connection-specific DNS Suffix  . : \n";
            output += "   IPv4 Address. . . . . . . . . . . : 10.10.10.100\n";
            output += "   Subnet Mask . . . . . . . . . . . : 255.255.255.0\n";
            output += "   Default Gateway . . . . . . . . . : 10.10.10.1\n\n";
        }
        
        return output;
    }

    function performPing() {
        const pingTarget = document.getElementById('pingTarget').value;
        const pingResults = document.getElementById('pingResults');
        pingResults.classList.remove('hidden');
        
        pingResults.textContent = `Pinging ${pingTarget}...\n`;
        
        // Simulate ping results
        setTimeout(() => {
            const output = simulatePing(pingTarget);
            pingResults.textContent += output;
            
            // Store the result
            testResults.networkInfo.ping = {
                target: pingTarget,
                output: output
            };
        }, 1000);
    }

    function simulatePing(target) {
        let output = `\nPinging ${target} with 32 bytes of data:\n`;
        
        // Simulate 4 ping responses
        const times = [10, 11, 9, 12];
        for (let i = 0; i < 4; i++) {
            output += `Reply from ${target}: bytes=32 time=${times[i]}ms TTL=128\n`;
        }
        
        // Ping statistics
        output += `\nPing statistics for ${target}:\n`;
        output += "    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),\n";
        output += "Approximate round trip times in milli-seconds:\n";
        output += "    Minimum = 9ms, Maximum = 12ms, Average = 10ms\n";
        
        return output;
    }

    function performTracert() {
        const tracertTarget = document.getElementById('tracertTarget').value;
        const tracertResults = document.getElementById('tracertResults');
        tracertResults.classList.remove('hidden');
        
        tracertResults.textContent = `Tracing route to ${tracertTarget}...\n`;
        
        // Simulate tracert results over time
        let hopCount = 0;
        const tracertInterval = setInterval(() => {
            const hopOutput = simulateTracertHop(hopCount, tracertTarget);
            tracertResults.textContent += hopOutput;
            
            hopCount++;
            if (hopCount > 7) {
                clearInterval(tracertInterval);
                
                // Store the final result
                testResults.networkInfo.tracert = {
                    target: tracertTarget,
                    output: tracertResults.textContent
                };
            }
        }, 300);
    }

    function simulateTracertHop(hop, target) {
        // Final hop
        if (hop === 7) {
            return `  ${hop + 1}    9 ms    8 ms    9 ms  ${target}\n\nTrace complete.\n`;
        }
        
        // Gateway hop
        if (hop === 0) {
            return `  ${hop + 1}    1 ms    1 ms    1 ms  192.168.1.1\n`;
        }
        
        // Random intermediate hops
        const rtt1 = Math.floor(Math.random() * 10) + 5;
        const rtt2 = Math.floor(Math.random() * 10) + 5;
        const rtt3 = Math.floor(Math.random() * 10) + 5;
        
        // Generate a plausible IP address for the hop
        const oct1 = 10 + Math.floor(Math.random() * 3);
        const oct2 = Math.floor(Math.random() * 256);
        const oct3 = Math.floor(Math.random() * 256);
        const oct4 = 1 + Math.floor(Math.random() * 254);
        const ipAddress = `${oct1}.${oct2}.${oct3}.${oct4}`;
        
        return `  ${hop + 1}    ${rtt1} ms    ${rtt2} ms    ${rtt3} ms  ${ipAddress}\n`;
    }

    function getWlanInfo() {
        const wlanInfo = document.getElementById('wlanInfo');
        wlanInfo.classList.remove('hidden');
        
        // Simulate wlan info output
        const output = simulateWlanInfo();
        wlanInfo.textContent = output;
        
        // Store the result
        testResults.networkInfo.wlanInfo = output;
    }

    function simulateWlanInfo() {
        if (testResults.config.connectionType !== 'WLAN') {
            return "No wireless interfaces detected.";
        }
        
        return `Interfaces:
  Name                   : Wi-Fi
  Description            : Intel(R) Wireless-AC 9560 160MHz
  GUID                   : c13d08e7-4ec7-4def-9b9e-bc32bf2247c7
  Physical address       : 64:5d:86:8b:c7:f2
  State                  : connected
  SSID                   : ABB-Corp
  BSSID                  : 00:1a:2b:3c:4d:5e
  Network type           : Infrastructure
  Radio type             : 802.11ac
  Authentication         : WPA2-Enterprise
  Cipher                 : CCMP
  Connection mode        : Auto Connect
  Channel                : 36
  Receive rate (Mbps)    : 866.7
  Transmit rate (Mbps)   : 866.7
  Signal                 : 90%
  Profile                : ABB-Corp
`;
    }

    function handleManualTestResult(testItem, status) {
        // Update visual indicator
        const indicator = testItem.querySelector('.status-indicator');
        indicator.className = 'status-indicator';
        
        if (status === 'success') {
            indicator.classList.add('success');
        } else if (status === 'failure') {
            indicator.classList.add('failure');
        } else if (status === 'skipped') {
            // Keep default gray
        }
        
        // Get test details
        const testName = testItem.querySelector('strong').textContent;
        const testDescription = testItem.querySelector('.test-details div')?.textContent || '';
        const url = testItem.dataset.url || '';
        
        // Record the result
        testResults.appTests.push({
            name: testName,
            description: testDescription,
            url: url,
            status: status,
            notes: ''
        });
        
        // Update the UI
        showFlashMessage(`Test "${testName}" marked as ${status}`, status === 'success' ? 'success' : status === 'failure' ? 'error' : 'info');
    }

    function generateResults() {
        // Calculate statistics
        const websiteStats = calculateStats(testResults.websiteTests);
        const appStats = calculateStats(testResults.appTests);
        const totalStats = {
            success: websiteStats.success + appStats.success,
            failure: websiteStats.failure + appStats.failure,
            skipped: websiteStats.skipped + appStats.skipped,
            total: websiteStats.total + appStats.total
        };
        
        // Update summary tab
        document.getElementById('websiteTestsSuccess').textContent = websiteStats.success;
        document.getElementById('websiteTestsFailed').textContent = websiteStats.failure;
        document.getElementById('websiteTestsSkipped').textContent = websiteStats.skipped;
        document.getElementById('websiteTestsTotal').textContent = websiteStats.total;
        
        document.getElementById('appTestsSuccess').textContent = appStats.success;
        document.getElementById('appTestsFailed').textContent = appStats.failure;
        document.getElementById('appTestsSkipped').textContent = appStats.skipped;
        document.getElementById('appTestsTotal').textContent = appStats.total;
        
        document.getElementById('overallSuccess').textContent = totalStats.success;
        document.getElementById('overallFailed').textContent = totalStats.failure;
        document.getElementById('overallSkipped').textContent = totalStats.skipped;
        document.getElementById('overallTotal').textContent = totalStats.total;
        
        // Update details tab
        const detailsTable = document.getElementById('detailsTable');
        
        // Clear existing rows except header
        while (detailsTable.rows.length > 1) {
            detailsTable.deleteRow(1);
        }
        
        // Add website tests
        testResults.websiteTests.forEach(test => {
            const row = detailsTable.insertRow();
            row.insertCell().textContent = test.name;
            row.insertCell().textContent = test.url;
            row.insertCell().textContent = test.status;
            row.insertCell().textContent = test.notes;
        });
        
        // Add application tests
        testResults.appTests.forEach(test => {
            const row = detailsTable.insertRow();
            row.insertCell().textContent = test.name;
            row.insertCell().textContent = test.description;
            row.insertCell().textContent = test.status;
            row.insertCell().textContent = test.notes;
        });
        
        // Update network info tab
        let networkSummary = '';
        
        if (testResults.networkInfo.publicIp) {
            networkSummary += `Public IP Information:\n`;
            networkSummary += `IP: ${testResults.networkInfo.publicIp.ip}\n`;
            networkSummary += `Location: ${testResults.networkInfo.publicIp.city}, ${testResults.networkInfo.publicIp.region}, ${testResults.networkInfo.publicIp.country}\n`;
            networkSummary += `Organization: ${testResults.networkInfo.publicIp.org}\n\n`;
        }
        
        if (testResults.networkInfo.ipConfig) {
            networkSummary += `IP Configuration:\n${testResults.networkInfo.ipConfig}\n\n`;
        }
        
        if (testResults.networkInfo.ping) {
            networkSummary += `Ping Results (${testResults.networkInfo.ping.target}):\n${testResults.networkInfo.ping.output}\n\n`;
        }
        
        if (testResults.networkInfo.tracert) {
            networkSummary += `Traceroute Results (${testResults.networkInfo.tracert.target}):\n${testResults.networkInfo.tracert.output}\n\n`;
        }
        
        if (testResults.networkInfo.wlanInfo) {
            networkSummary += `WLAN Information:\n${testResults.networkInfo.wlanInfo}\n\n`;
        }
        
        document.getElementById('networkInfoSummary').textContent = networkSummary;
    }

    function calculateStats(tests) {
        return {
            success: tests.filter(t => t.status === 'success').length,
            failure: tests.filter(t => t.status === 'failure').length,
            skipped: tests.filter(t => t.status === 'skipped').length,
            total: tests.length
        };
    }

    function activateTab(tabId) {
        // Deactivate all tabs
        document.querySelectorAll('.tab').forEach(tab => tab.classList.remove('active'));
        document.querySelectorAll('.tab-pane').forEach(pane => pane.classList.remove('active'));
        
        // Activate the selected tab
        document.querySelector(`.tab[data-tab="${tabId}"]`).classList.add('active');
        document.getElementById(`${tabId}Tab`).classList.add('active');
    }

    function saveReport() {
        // Generate CSV content
        let csvContent = "data:text/csv;charset=utf-8,";
        
        // Add header
        csvContent += "UAT Report for Change " + testResults.config.changeNumber + "\n";
        csvContent += "Generated: " + formatDate(new Date()) + "\n";
        csvContent += "User: " + testResults.config.username + "\n";
        csvContent += "Computer: " + testResults.config.hostname + "\n";
        csvContent += "Connection Type: " + testResults.config.connectionType + "\n\n";
        
        // Add website tests
        csvContent += "Website Tests\n";
        csvContent += "Name,URL,Status,Notes\n";
        testResults.websiteTests.forEach(test => {
            csvContent += `"${test.name}","${test.url}","${test.status}","${test.notes}"\n`;
        });
        
        csvContent += "\nApplication Tests\n";
        csvContent += "Name,Description,Status,Notes\n";
        testResults.appTests.forEach(test => {
            csvContent += `"${test.name}","${test.description}","${test.status}","${test.notes}"\n`;
        });
        
        csvContent += "\nSummary\n";
        csvContent += "Category,Success,Failed,Skipped,Total\n";
        const websiteStats = calculateStats(testResults.websiteTests);
        const appStats = calculateStats(testResults.appTests);
        const totalStats = {
            success: websiteStats.success + appStats.success,
            failure: websiteStats.failure + appStats.failure,
            skipped: websiteStats.skipped + appStats.skipped,
            total: websiteStats.total + appStats.total
        };
        
        csvContent += `"Website Tests",${websiteStats.success},${websiteStats.failure},${websiteStats.skipped},${websiteStats.total}\n`;
        csvContent += `"Application Tests",${appStats.success},${appStats.failure},${appStats.skipped},${appStats.total}\n`;
        csvContent += `"Overall",${totalStats.success},${totalStats.failure},${totalStats.skipped},${totalStats.total}\n\n`;
        
        csvContent += "Comments:\n";
        csvContent += `"${testResults.comments}"\n`;
        
        // Create a download link
        const encodedUri = encodeURI(csvContent);
        const link = document.createElement("a");
        link.setAttribute("href", encodedUri);
        link.setAttribute("download", `UAT_Report_${testResults.config.changeNumber}_${formatDate(new Date()).replace(/[: ]/g, '-')}.csv`);
        document.body.appendChild(link);
        
        // Trigger the download
        link.click();
        
        // Clean up
        document.body.removeChild(link);
        
        showFlashMessage("Report downloaded successfully!", "success");
    }

    function resetAndStartOver() {
        // Reset global state
        testResults.websiteTests = [];
        testResults.appTests = [];
        testResults.networkInfo = {
            publicIp: null,
            ipConfig: null,
            ping: null,
            tracert: null,
            wlanInfo: null
        };
        testResults.comments = '';
        
        // Reset UI
        document.querySelectorAll('.status-indicator').forEach(indicator => {
            indicator.className = 'status-indicator';
        });
        
        document.querySelectorAll('.code-display').forEach(display => {
            display.classList.add('hidden');
            display.textContent = '';
        });
        
        document.getElementById('userComments').value = '';
        document.getElementById('changeNumber').value = '';
        document.getElementById('connectionType').value = '';
        
        // Show configuration section
        document.getElementById('testProgress').classList.add('hidden');
        document.getElementById('configSection').classList.remove('hidden');
        
        // Hide all other sections
        document.getElementById('websiteTestsSection').classList.add('hidden');
        document.getElementById('networkInfoSection').classList.add('hidden');
        document.getElementById('appTestsSection').classList.add('hidden');
        document.getElementById('resultsSection').classList.add('hidden');
        
        showFlashMessage("Started a new test session", "info");
    }

    function showFlashMessage(message, type = 'info') {
        const flashMessage = document.getElementById('flashMessage');
        flashMessage.textContent = message;
        flashMessage.className = `flash-message ${type === 'error' ? 'error' : type === 'success' ? 'success' : 'info'}`;
        
        setTimeout(() => {
            flashMessage.className = 'flash-message';
        }, 5000);
    }

    function setActiveStep(stepNumber) {
        // Update the progress steps
        for (let i = 1; i <= 5; i++) {
            const step = document.getElementById(`step${i}`);
            
            if (i < stepNumber) {
                step.className = 'step completed';
            } else if (i === stepNumber) {
                step.className = 'step active';
            } else {
                step.className = 'step';
            }
        }
        
        // Update progress bar
        const progressPercent = ((stepNumber - 1) / 4) * 100;
        document.getElementById('progressBar').style.width = `${progressPercent}%`;
    }

    function showSection(sectionId) {
        // Hide all sections
        document.getElementById('websiteTestsSection').classList.add('hidden');
        document.getElementById('networkInfoSection').classList.add('hidden');
        document.getElementById('appTestsSection').classList.add('hidden');
        document.getElementById('resultsSection').classList.add('hidden');
        
        // Show the requested section
        document.getElementById(sectionId).classList.remove('hidden');
    }
});