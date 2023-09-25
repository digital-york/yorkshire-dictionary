Attribute VB_Name = "Module1"
Option Explicit
Public Sub CombineSheetsWithDifferentHeaders()
    
    Dim wksDst As Worksheet, wksSrc As Worksheet
    Dim lngIdx As Long, lngLastSrcColNum As Long, _
        lngFinalHeadersCounter As Long, lngFinalHeadersSize As Long, _
        lngLastSrcRowNum As Long, lngLastDstRowNum As Long
    Dim strColHeader As String
    Dim varColHeader As Variant
    Dim rngDst As Range, rngSrc As Range
    Dim dicFinalHeaders As Dictionary
    Set dicFinalHeaders = New Dictionary
    
    'Set references up-front
    dicFinalHeaders.CompareMode = vbTextCompare
    lngFinalHeadersCounter = 1
    lngFinalHeadersSize = dicFinalHeaders.Count
    Set wksDst = ThisWorkbook.Worksheets.Add
    
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    'Start Phase 1: Prepare Final Headers and Destination worksheet'
    ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    'First, we loop through all of the data worksheets,
    'building our Final Headers dictionary
    For Each wksSrc In ThisWorkbook.Worksheets
    
        'Make sure we skip the Destination worksheet!
        If wksSrc.Name <> wksDst.Name Then
        
            With wksSrc
        
                'Loop through all of the headers on this sheet,
                'adding them to the Final Headers dictionary
                lngLastSrcColNum = LastOccupiedColNum(wksSrc)
                For lngIdx = 1 To lngLastSrcColNum
                
                    'If this column header does NOT already exist in the Final
                    'Headers dictionary, add it and increment the column number
                    strColHeader = Trim(CStr(.Cells(1, lngIdx)))
                    If Not dicFinalHeaders.Exists(strColHeader) Then
                        dicFinalHeaders.Add Key:=strColHeader, _
                                            Item:=lngFinalHeadersCounter
                        lngFinalHeadersCounter = lngFinalHeadersCounter + 1
                    End If
                
                Next lngIdx
                
            End With
            
        End If
        
    Next wksSrc
    
    'Wahoo! The Final Headers dictionary now contains every column
    'header name from the worksheets. Let's write these values into
    'the Destination worksheet and finish Phase 1
    For Each varColHeader In dicFinalHeaders.Keys
        wksDst.Cells(1, dicFinalHeaders(varColHeader)) = CStr(varColHeader)
    Next varColHeader
    
    '''''''''''''''''''''''''''''''''''''''''''''''
    'End Phase 1: Final Headers are ready to rock!'
    '''''''''''''''''''''''''''''''''''''''''''''''
    
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    'Start Phase 2: write the data from each worksheet to the Destination!'
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
    
    'We begin just like Phase 1 -- by looping through each sheet
    For Each wksSrc In ThisWorkbook.Worksheets
    
        'Once again, make sure we skip the Destination worksheet!
        If wksSrc.Name <> wksDst.Name Then
        
            With wksSrc
        
                'Identify the last row and column on this sheet
                'so we know when to stop looping through the data
                lngLastSrcRowNum = LastOccupiedRowNum(wksSrc)
                lngLastSrcColNum = LastOccupiedColNum(wksSrc)
                
                'Identify the last row of the Destination sheet
                'so we know where to (eventually) paste the data
                lngLastDstRowNum = LastOccupiedRowNum(wksDst)
                
                'Loop through the headers on this sheet, looking up
                'the appropriate Destination column from the Final
                'Headers dictionary and creating ranges on the fly
                For lngIdx = 1 To lngLastSrcColNum
                    strColHeader = Trim(CStr(.Cells(1, lngIdx)))
                    
                    'Set the Destination target range using the
                    'looked up value from the Final Headers dictionary
                    Set rngDst = wksDst.Cells(lngLastDstRowNum + 1, _
                                              dicFinalHeaders(strColHeader))
                                              
                    'Set the source target range using the current
                    'column number and the last-occupied row
                    Set rngSrc = .Range(.Cells(2, lngIdx), _
                                        .Cells(lngLastSrcRowNum, lngIdx))
                    
                    'Copy the data from this sheet to the destination!
                    rngSrc.Copy Destination:=rngDst
                    
                Next lngIdx
            
            End With
        
        End If
    
    Next wksSrc
    
    'Yay! Let the user know that the data has been combined
    MsgBox "Data combined!"

End Sub

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'INPUT       : Sheet, the worksheet we'll search to find the last row
'OUTPUT      : Long, the last occupied row
'SPECIAL CASE: if Sheet is empty, return 1
Public Function LastOccupiedRowNum(Sheet As Worksheet) As Long
    Dim lng As Long
    If Application.WorksheetFunction.CountA(Sheet.Cells) <> 0 Then
        With Sheet
            lng = .Cells.Find(What:="*", _
                              After:=.Range("A1"), _
                              Lookat:=xlPart, _
                              LookIn:=xlFormulas, _
                              SearchOrder:=xlByRows, _
                              SearchDirection:=xlPrevious, _
                              MatchCase:=False).Row
        End With
    Else
        lng = 1
    End If
    LastOccupiedRowNum = lng
End Function

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'INPUT       : Sheet, the worksheet we'll search to find the last column
'OUTPUT      : Long, the last occupied column
'SPECIAL CASE: if Sheet is empty, return 1
Public Function LastOccupiedColNum(Sheet As Worksheet) As Long
    Dim lng As Long
    If Application.WorksheetFunction.CountA(Sheet.Cells) <> 0 Then
        With Sheet
            lng = .Cells.Find(What:="*", _
                              After:=.Range("A1"), _
                              Lookat:=xlPart, _
                              LookIn:=xlFormulas, _
                              SearchOrder:=xlByColumns, _
                              SearchDirection:=xlPrevious, _
                              MatchCase:=False).Column
        End With
    Else
        lng = 1
    End If
    LastOccupiedColNum = lng
End Function

