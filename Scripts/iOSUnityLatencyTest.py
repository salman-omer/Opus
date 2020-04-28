import matplotlib.pyplot as plt

file1 = open('iphone6UnityIOSDelays.txt', 'r')
Lines = file1.readlines()
file1.close()


iPhone6Delays = []

for line in Lines:
    iPhone6Delays.append(float(line.split()[-1]))


file1 = open('iphone11UnityIOSDelays.txt', 'r')
Lines = file1.readlines()
file1.close()


iPhone11Delays = []

for line in Lines:
    iPhone11Delays.append(float(line.split()[-1]))

delays = []
delays.append(iPhone6Delays)
delays.append(iPhone11Delays)

fig1, ax1 = plt.subplots()
ax1.set_title(
    'iPhone iOS-Unity Message Latency in Seconds (~400 Samples each)')
ax1.boxplot(delays)
ax1.set_xticklabels(['iPhone 6s', 'iPhone 11'])

plt.show()
