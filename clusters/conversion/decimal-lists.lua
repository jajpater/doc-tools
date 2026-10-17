-- Org kent alleen cijferbullets ("1." en "1)"), maar pandoc's Org-lezer geeft
-- genummerde lijsten geen stijl mee.  De docx-writer nummert een geneste lijst
-- dan met letters; deze filter houdt elk niveau bij cijfers.
function OrderedList(el)
  if el.listAttributes.style == "DefaultStyle" then
    el.listAttributes.style = "Decimal"
  end
  return el
end
