import { useState } from 'react'
import axios from 'axios'
import './App.css'

// Point to Python Backend
const API_BASE = 'http://127.0.0.1:5000';

function App() {
  const [file, setFile] = useState(null)
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState(null)
  const [score, setScore] = useState(0)
  const [error, setError] = useState('')
  // Track selected chart
  const [selectedChartIndex, setSelectedChartIndex] = useState(0)

  const handleFileChange = (e) => {
    setFile(e.target.files[0])
    setData(null)
    setScore(0)
    setError('')
    setSelectedChartIndex(0)
  }

  const handleUpload = async () => {
    if (!file) {
      setError('Please select a file first.')
      return
    }

    setLoading(true)
    setError('')

    const formData = new FormData()
    formData.append('dataset', file)

    try {
      const response = await axios.post(`${API_BASE}/upload`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      })

      if (response.data.error) {
        setError(response.data.error)
      } else {
        setData(response.data)
        // Animate score
        let current = 0
        const interval = setInterval(() => {
          current += 1
          if (current >= response.data.score) {
            clearInterval(interval)
            setScore(response.data.score)
          } else {
            setScore(current)
          }
        }, 20)
      }
    } catch (err) {
      console.error(err)
      if (err.response && err.response.data && err.response.data.error) {
        setError(err.response.data.error)
      } else {
        setError('Failed to connect to the analysis engine. Ensure "py app.py" is running.')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="app-container">
      <div className="content-wrapper">
        <header className="main-header">
          <h1>Smart Visualizer 🚀</h1>
          <p>Upload your dataset to generate AI-powered visualization insights.</p>
        </header>

        {/* NotebookLM / Easter Egg Section */}
        <div className="card feature-card">
          <h2>🎧 NotebookLM Audio Overview</h2>
          <div className="input-group">
            <p>Upload your generated Audio Overview (MP3/WAV)</p>
            <input type="file" className="file-input-simple" accept="audio/*" />
          </div>
          <div className="glow-effect"></div>
        </div>

        {/* Main Upload Area */}
        <div className="card upload-card">
          <div className="drop-zone">
            <div className="icon">📂</div>
            <p><strong>Click to upload</strong> or drag and drop</p>
            <p className="small">CSV or Excel</p>
            <input type="file" className="file-input-hidden" onChange={handleFileChange} accept=".csv,.xlsx" />
          </div>
          {file && <p className="file-selected">Selected: {file.name}</p>}

          <button
            onClick={handleUpload}
            disabled={loading}
            className={`btn-primary ${loading ? 'loading' : ''}`}
          >
            {loading ? 'Processing Intelligence...' : 'Generate Analysis & Charts'}
          </button>

          {error && <div className="error-msg">{error}</div>}
        </div>

        {/* Results Section */}
        {data && data.plots && (
          <div className="results-section">
            {/* Score removed */}


            <div className="chart-controls">
              <label>Select Visualization:</label>
              <select
                className="chart-dropdown"
                value={selectedChartIndex}
                onChange={(e) => setSelectedChartIndex(Number(e.target.value))}
              >
                {data.plots.map((plot, idx) => (
                  <option key={idx} value={idx}>
                    {idx + 1}. {plot.title}
                  </option>
                ))}
              </select>
            </div>

            <div className="active-chart-container">
              {data.plots[selectedChartIndex] && (
                <div className="chart-card large">
                  <div className="chart-header">
                    <span className="chart-tag">FIG_{selectedChartIndex + 1}</span>
                    <span className="chart-title-inline">{data.plots[selectedChartIndex].title || ''}</span>
                  </div>
                  <img
                    src={data.plots[selectedChartIndex].image}
                    alt={data.plots[selectedChartIndex].title || 'Chart'}
                  />
                </div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

export default App
