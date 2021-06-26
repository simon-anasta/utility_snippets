library(pdftools)
setwd("c:/NotBackedUp/local R dev/pdfs combine/doc1/")
dir()

pdf_length("pg4.pdf")

pdf_combine(c("pg1.pdf", "pg2.pdf", "pg3.pdf", "pg4.pdf"), "joined.pdf")

setwd("c:/NotBackedUp/local R dev/pdfs combine/doc2/")
dir()

pdf_subset("MASTER SWA - IEA Mar 20 FINAL.pdf", pages = 1:3, output = "subset.pdf")

pdf_combine(c("subset.pdf",
              "pg4.pdf",
              "pg5.pdf",
              "pg6.pdf",
              "pg7.pdf",
              "pg8.pdf",
              "pg9.pdf",
              "pg10.pdf",
              "pg11.pdf",
              "pg12.pdf",
              "pg13.pdf",
              "pg14.pdf"),
            "joined.pdf")


library(pdftools)
setwd("\\\\corp.ssi.govt.nz/userss/sanas001/Documents/Simon's Documents/Ben")
dir()

pdf_combine(c("Scan_4886_001_02-10-2020.pdf", "Scan_4890_001_02-10-2020.pdf"), "Ben drivers license.pdf")
pdf_combine(c("Scan_4887_001_02-10-2020.pdf", "Scan_4888_001_02-10-2020.pdf"), "Ben vetting form.pdf")
