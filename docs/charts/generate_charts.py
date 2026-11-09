import matplotlib.pyplot as plt

# Area progression
stages = ["Synthesis", "Floorplan", "Placement", "CTS", "Final"]
areas = [17332.87, 18279, 18519, 18798, 18798]

plt.figure(figsize=(9, 5))
bars = plt.bar(stages, areas)
plt.title("ALU+ CHAMO - Cell Area Evolution")
plt.ylabel("Cell area (um²)")
plt.ylim(0, 22000)

for bar, value in zip(bars, areas):
    plt.text(
        bar.get_x() + bar.get_width()/2,
        value + 250,
        f"{value:,.0f}",
        ha="center"
    )

plt.tight_layout()
plt.savefig("docs/charts/area_evolution.png", dpi=200)
plt.close()

# Frequency comparison
stages = ["Floorplan", "Post-route"]
frequencies = [20.41, 17.77]

plt.figure(figsize=(7, 5))
bars = plt.bar(stages, frequencies)
plt.title("ALU+ CHAMO - Timing Evolution")
plt.ylabel("Estimated Fmax (MHz)")
plt.ylim(0, 25)

for bar, value in zip(bars, frequencies):
    plt.text(
        bar.get_x() + bar.get_width()/2,
        value + 0.4,
        f"{value:.2f} MHz",
        ha="center"
    )

plt.tight_layout()
plt.savefig("docs/charts/timing_evolution.png", dpi=200)
plt.close()

print("CHARTS_GENERATED")
