// window.onload=show;

/*------------------------------------------------------------------------------------ADDED-*/
var lastBranch;
var lastBranchclass;
/*------------------------------------------------------------------------------------ADDED END-*/

function show(id) 
{
   if (id!=null)
   {
      var d = document.getElementById(id);
      for (var i = 1; i<=10; i++) 
      {
         if (document.getElementById('smenu'+i)) 
         {
            document.getElementById('smenu'+i).style.display='none';
         }
      }

      if (d) 
      {
         d.style.display='block';

/*------------------------------------------------------------------------------------ADDED-*/
         if (event.srcElement!=null)
         {
            if (lastBranch!=null) lastBranch.className=lastBranchclass;
            lastBranch=event.srcElement;
            lastBranchclass=lastBranch.className;
            lastBranch.className=lastBranch.className+"d";
         }
/*------------------------------------------------------------------------------------ADDED END-*/

      }
   }
   else
   {
       alert("what do you want to happen now ?");
   }
}

var branchMenu=new Array();
var savebranchMenu=new Array();

function save_click(v)
{
	savebranchMenu.push(v);
}

function init_click()
{
	savebranchMenu=savebranchMenu.reverse();	
	for(var i=0; i<savebranchMenu.length;i++)
	{
		branch_click(savebranchMenu[i]);
	}
}

function branchd_click()
{
   window.status="branchd_click";
       
   var an = event.srcElement;
   if      (an.tagName=='DIV') an=an.parentElement;
   else if (an.tagName=='DT')  an=an.children[0];
   
   for (i=branchMenu.length-1;i>=0;i--)
   {
      var next=branchMenu.pop();
    
      if (next!=null)
      {
         next.className='branch';

         if (next.parentElement.className=="subactived") 
            next.parentElement.className="subactive";

         next.parentElement.nextSibling.style.display='none';
      }
      if (next==an) return;      
   } 
}

function branch_click(an)
{
   if (an==null) an=event.srcElement;
   if      (an.tagName=='DIV') an=an.parentElement;
   else if (an.tagName=='DT')  an=an.children[0];

   var dt=(an.tagName!='DT' ? an.parentElement : an);
   var sub=dt.nextSibling;
   window.status="branch_click";

   if (sub!=null && sub.tagName=='DD')
   {
      if (branchMenu!=null && branchMenu.length>0)
      {
         for (i=branchMenu.length-1;i>=0;i--)
         {
            var next=branchMenu.pop();
            var sub2=next.parentElement.nextSibling;

            if (sub2.all[sub.id]==null)
            {
               window.status+=" close ("+sub2.tagName+","+sub2.id+","+next.className+")";
               next.className='branch';
               if (next.parentElement.className=="subactived") 
                  next.parentElement.className="subactive";
               next.parentElement.nextSibling.style.display='none';
            }
            else
            {
               window.status+=" child of "+sub2.id;
               branchMenu.push(next);
               break;
            }
         } 
      }
 
      an.className='branchd';
      if (an.parentElement.className=="subactive") 
          an.parentElement.className="subactived";
 
      sub.style.display='block';
      window.status=window.status+" . open ("+sub.tagName+","+sub.id+","+an.className+")";
      branchMenu.push(an);
   }   
   else
   {
       window.status='parent of anchor has no sibling of type DD ';
   }
   return;
}

function branch_initial(an)
{
   if (an.tagName=='DT')
      an=an.children[0];

   an.className='branchd';
   branchMenu.push(an);
}



