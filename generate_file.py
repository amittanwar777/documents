import matplotlib.pyplot as plt
import matplotlib.patches as patches

def create_pdf():
    # Create a figure and a single subplot
    fig, ax = plt.subplots()

    # Add a rectangle
    rect = patches.Rectangle((0.1, 0.5), 0.6, 0.3, linewidth=1, edgecolor='r', facecolor='none')
    ax.add_patch(rect)

    # Add a circle
    circle = patches.Circle((0.7, 0.2), 0.1, linewidth=1, edgecolor='b', facecolor='none')
    ax.add_patch(circle)

    # Set limits and remove axes
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis('off')

    # Save the figure as a PDF
    plt.savefig("output.pdf", bbox_inches='tight')

if __name__ == "__main__":
    create_pdf()
