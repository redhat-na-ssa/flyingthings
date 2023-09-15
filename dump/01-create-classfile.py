#!/opt/app-root/bin/python
from jinja2 import Environment, FileSystemLoader

# Read the names from the "classes.txt" file, skipping blank lines
with open('classes.txt', 'r') as file:
    names = [line.strip() for line in file if line.strip()]

# Set nc equal to the size of the names array
nc = len(names)

# Create a Jinja2 environment and load the template file
env = Environment(loader=FileSystemLoader('.'))
template = env.get_template('classes.yaml.j2')

# Render the template with the names array and nc variable
output = template.render(names=names, nc=nc)

# Write the rendered output to a new file called "classes.yaml"
with open('classes.yaml', 'w') as outfile:
    outfile.write(output)

print("Rendered output has been written to classes.yaml")
