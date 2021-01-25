extends Resource
class_name WaveFileImport

# Thanks: https://github.com/Gianclgar/GDScriptAudioImport/blob/master/GDScriptAudioImport.gd
func import_wav(bytes : PoolByteArray) -> AudioStreamSample:
	"""
	Import a .WAV file correctly at runtime
	"""
	var newstream := AudioStreamSample.new()

	for i in range(0, 100):
		var those4bytes = str(char(bytes[i]) + char(bytes[i + 1]) + char(bytes[i + 2]) + char(bytes[i + 3]))

		if those4bytes == "RIFF": 
			print("RIFF OK at bytes " + str(i) + "-" + str(i+3))
			# RIP bytes 4-7 integer for now
		elif those4bytes == "WAVE": 
			print("WAVE OK at bytes " + str(i) + "-" + str(i+3))
		elif those4bytes == "fmt ":
			print("fmt OK at bytes " + str(i) + "-" + str(i+3))

			# Get format subchunk size, 4 bytes next to "fmt " are an int32
			var formatsubchunksize = bytes[i + 4] + (bytes[i + 5] << 8) + (bytes[i + 6] << 16) + (bytes[i + 7] << 24)
			print("Format subchunk size: " + str(formatsubchunksize))
			
			# Using formatsubchunk index so it's easier to understand what's going on
			var fsc0 = i+8 #fsc0 is byte 8 after start of "fmt "

			# Get format code [Bytes 0-1]
			var format_code = bytes[fsc0] + (bytes[fsc0 + 1] << 8)
			var format_name := ""

			if format_code == 0: 
				format_name = "8_BITS"
			elif format_code == 1:
				format_name = "16_BITS"
			elif format_code == 2:
				format_name = "IMA_ADPCM"

			print("Format: " + str(format_code) + " " + format_name)
			
			# Assign format to our AudioStreamSample
			newstream.format = format_code

			# Get channel num [Bytes 2-3]
			var channel_num = bytes[fsc0 + 2] + (bytes[fsc0 + 3] << 8)
			print("Number of channels: " + str(channel_num))

			# Set our AudioStreamSample to stereo if needed
			if channel_num == 2:
				newstream.stereo = true

			# Get sample rate [Bytes 4-7]
			var sample_rate = bytes[fsc0 + 4] + (bytes[fsc0 + 5] << 8) + (bytes[fsc0 + 6] << 16) + (bytes[fsc0 + 7] << 24)
			print("Sample rate: " + str(sample_rate))
			
			# Set our AudioStreamSample mixrate
			newstream.mix_rate = sample_rate
			
			# Get byte_rate [Bytes 8-11] because we can
			var byte_rate = bytes[fsc0 + 8] + (bytes[fsc0 + 9] << 8) + (bytes[fsc0 + 10] << 16) + (bytes[fsc0 + 11] << 24)
			print("Byte rate: " + str(byte_rate))

			# Same with bits*sample*channel [Bytes 12-13]
			var bits_sample_channel = bytes[fsc0+12] + (bytes[fsc0+13] << 8)
			print("BitsPerSample * Channel / 8: " + str(bits_sample_channel))

			# And bits per sample [Bytes 14-15]
			var bits_per_sample = bytes[fsc0 + 14] + (bytes[fsc0 + 15] << 8)
			print("Bits per sample: " + str(bits_per_sample))
		elif those4bytes == "data":
			var audio_data_size = bytes[i + 4] + (bytes[i + 5] << 8) + (bytes[i + 6] << 16) + (bytes[i + 7] << 24)
			print("Audio data/stream size is " + str(audio_data_size) + " bytes")

			var data_entry_point = (i + 8)
			print("Audio data starts at byte " + str(data_entry_point))
			
			newstream.data = bytes.subarray(data_entry_point, data_entry_point + audio_data_size - 1)

	# Get samples and set loop end
	var samplenum = int(newstream.data.size() / 4.0)
	newstream.loop_end = samplenum
	newstream.loop_mode = 0 # No loop
	return newstream
