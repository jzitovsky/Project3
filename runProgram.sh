docker build -t strex .
nextflow main.nf 
docker run -d -p 3838:3838 -p 8787:8787 -e ADD=shiny -e PASSWORD=1234 -v $(pwd):/srv/shiny-server strex
