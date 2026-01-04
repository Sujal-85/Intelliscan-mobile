import io
import tempfile
import os
import numpy as np
import soundfile as sf
from scipy import signal
from pydub import AudioSegment

class AudioEnhancer:
    def __init__(self):
        pass
    
    def enhance(self, audio_data: bytes, enhancement_type: str = "denoise", original_filename: str = "audio.wav") -> str:
        """
        Enhance audio quality based on the specified enhancement type
        Returns path to the enhanced audio file
        """
        try:
            # Save the uploaded audio to a temporary file
            temp_input = tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(original_filename)[1])
            temp_input.write(audio_data)
            temp_input.close()
            
            # Load the audio file
            audio = AudioSegment.from_file(temp_input.name)
            
            # Apply the specified enhancement
            enhanced_audio = None
            if enhancement_type == "denoise":
                enhanced_audio = self._reduce_noise(audio)
            elif enhancement_type == "amplify":
                enhanced_audio = self._amplify_audio(audio)
            elif enhancement_type == "normalize":
                enhanced_audio = self._normalize_audio(audio)
            else:
                # Default to denoise if unknown type
                enhanced_audio = self._reduce_noise(audio)
            
            # Save enhanced audio to temporary file
            temp_output = tempfile.NamedTemporaryFile(delete=False, suffix=".wav")
            temp_output.close()
            
            enhanced_audio.export(temp_output.name, format="wav")
            
            # Clean up temporary input file
            os.unlink(temp_input.name)
            
            return temp_output.name
        except Exception as e:
            print(f"Error in audio enhancement: {str(e)}")
            # Return the original file if enhancement fails
            temp_input = tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(original_filename)[1])
            temp_input.write(audio_data)
            temp_input.close()
            return temp_input.name
    
    def _reduce_noise(self, audio: AudioSegment) -> AudioSegment:
        """
        Apply noise reduction to the audio
        """
        try:
            # Simple noise reduction by reducing overall volume slightly and applying a filter
            # First, convert to raw data
            samples = np.array(audio.get_array_of_samples())
            
            # Apply a low-pass filter to remove high-frequency noise
            nyquist = audio.frame_rate / 2
            cutoff = 0.8 * nyquist  # 80% of Nyquist frequency
            b, a = signal.butter(8, cutoff / nyquist, btype='low')
            
            # Apply filter (mono only for simplicity, stereo would need separate channels)
            if audio.channels == 2:
                # For stereo, we'll process each channel separately
                left_channel = samples[::2]
                right_channel = samples[1::2]
                
                left_filtered = signal.filtfilt(b, a, left_channel)
                right_filtered = signal.filtfilt(b, a, right_channel)
                
                # Reconstruct stereo
                filtered_samples = np.empty(len(samples), dtype=samples.dtype)
                filtered_samples[::2] = left_filtered.astype(samples.dtype)
                filtered_samples[1::2] = right_filtered.astype(samples.dtype)
            else:
                # Mono
                filtered_samples = signal.filtfilt(b, a, samples)
            
            # Create new AudioSegment with filtered data
            enhanced_audio = audio._spawn(filtered_samples.astype(np.int16))
            
            return enhanced_audio
        except:
            # If advanced filtering fails, use simple pydub methods
            return audio.low_pass_filter(3000).high_pass_filter(100)
    
    def _amplify_audio(self, audio: AudioSegment) -> AudioSegment:
        """
        Amplify the audio by increasing volume
        """
        try:
            # Increase volume by 10dB (adjust as needed)
            amplified_audio = audio + 10
            return amplified_audio
        except:
            return audio
    
    def _normalize_audio(self, audio: AudioSegment) -> AudioSegment:
        """
        Normalize the audio to optimal levels
        """
        try:
            # Normalize to -1.0 dB (standard for most applications)
            normalized_audio = audio.normalize(headroom=1.0)
            return normalized_audio
        except:
            return audio

# Example usage
if __name__ == "__main__":
    enhancer = AudioEnhancer()
    # Example would go here