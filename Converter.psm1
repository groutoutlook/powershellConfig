
function ConvertTo-Pdf($path){
    # Ensure input is a file object so .Extension works
    $fileItem = Get-Item -Path $path
    
    switch -Regex ($fileItem.Extension) {
        {".doc"}{
            soffice --convert-to pdf $path
        }
        {".xls",".xlsx"}{
            soffice --convert-to pdf $path
        }
    }
    
}
