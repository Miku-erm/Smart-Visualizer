document.addEventListener('DOMContentLoaded', () => {
    const uploadForm = document.getElementById('uploadForm');
    const audioInput = document.getElementById('audioInput');
    const audioPlayer = document.getElementById('audioPlayer');
    const chartsGrid = document.getElementById('chartsGrid');
    const scoreSection = document.getElementById('scoreSection');
    const scoreValue = document.getElementById('scoreValue');
    const aiSection = document.getElementById('aiSection');
    const askAiBtn = document.getElementById('askAiBtn');
    const aiPrompt = document.getElementById('aiPrompt');
    const aiResponse = document.getElementById('aiResponse');

    let datasetSummary = "";

    // Handle Audio Overview Preview
    audioInput.addEventListener('change', function (e) {
        const file = e.target.files[0];
        if (file) {
            const url = URL.createObjectURL(file);
            audioPlayer.src = url;
            audioPlayer.style.display = 'block';
        }
    });

    // Handle Dataset Upload & Chart Generation
    uploadForm.addEventListener('submit', async (e) => {
        e.preventDefault();

        const formData = new FormData(uploadForm);
        const submitBtn = uploadForm.querySelector('button');
        const originalText = submitBtn.innerText;
        submitBtn.innerText = "Processing & Drawing...";
        submitBtn.disabled = true;

        try {
            const response = await fetch('/upload', {
                method: 'POST',
                body: formData
            });

            const data = await response.json();

            if (response.ok) {
                // Update Score
                scoreSection.classList.remove('hidden');
                chartsGrid.classList.remove('hidden');
                aiSection.classList.remove('hidden');

                // Animate Score
                let currentScore = 0;
                const targetScore = data.score;
                const interval = setInterval(() => {
                    if (currentScore >= targetScore) {
                        clearInterval(interval);
                    } else {
                        currentScore++;
                        scoreValue.innerText = currentScore;
                    }
                }, 20);

                // Render Charts
                chartsGrid.innerHTML = '';
                data.charts.forEach(chart => {
                    const chartDiv = document.createElement('div');
                    chartDiv.className = 'chart-card';
                    chartDiv.innerHTML = `
                        <h3>${chart.title}</h3>
                        <img src="data:image/png;base64,${chart.image}" alt="${chart.title}">
                        <p class="small">${chart.desc}</p>
                    `;
                    chartsGrid.appendChild(chartDiv);
                });

                // Save summary for AI
                datasetSummary = data.data_summary;

            } else {
                alert('Error: ' + data.error);
            }
        } catch (error) {
            alert('An unexpected error occurred: ' + error);
        } finally {
            submitBtn.innerText = originalText;
            submitBtn.disabled = false;
        }
    });

    // Handle AI Request
    askAiBtn.addEventListener('click', async () => {
        const prompt = aiPrompt.value;
        const apiKey = document.getElementById('apiKeyInput').value; // Optional client-side override

        if (!prompt) return;

        askAiBtn.disabled = true;
        askAiBtn.innerText = "Thinking...";
        aiResponse.classList.add('hidden');
        aiResponse.innerText = '';

        try {
            const response = await fetch('/ask-ai', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    prompt: prompt,
                    context: datasetSummary
                    // In a real production app, sending API key from client might be insecure if not handled carefully,
                    // but for this weekly project, it's a valid way to allow flexible key usage if env var isn't set.
                })
            });

            const data = await response.json();
            if (data.response) {
                aiResponse.innerText = data.response;
                aiResponse.classList.remove('hidden');
            } else {
                aiResponse.innerText = "Error: " + (data.error || "Unknown error");
                aiResponse.classList.remove('hidden');
            }
        } catch (error) {
            aiResponse.innerText = "Network Error: " + error;
            aiResponse.classList.remove('hidden');
        } finally {
            askAiBtn.disabled = false;
            askAiBtn.innerText = "Ask Gemini";
        }
    });
});
