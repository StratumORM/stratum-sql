�� 
  
 - - e x e c   [ o r m ] . [ p r o p e r t y _ r e n a m e ]   ' s q u a r e ' ,   ' c o l o u r ' ,   ' c o l o r '  
 - - e x e c   [ o r m ] . [ p r o p e r t y _ r e n a m e ]   ' s q u a r e ' ,   ' c o l o r ' ,   ' c o l o u r '  
 g o  
  
 s e l e c t   *   f r o m   [ o r m ] . [ t r i a n g l e _ w i d e ]  
 s e l e c t   *   f r o m   [ o r m ] . [ s q u a r e _ w i d e ]  
 s e l e c t   *   f r o m   [ o r m ] . [ p e n t a g o n _ w i d e ]  
 s e l e c t   *   f r o m   [ o r m ] . [ s q e n t a g o n _ w i d e ]  
  
 g o  
  
 s e l e c t 	 t . n a m e   a s   [ t e m p l a t e ]  
 	 , 	 o . n a m e   a s   [ o b j e c t ]  
 	 , 	 p . n a m e   a s   [ p r o p e r t y ]  
 	 , 	 v . v a l u e  
 	 , 	 t . t e m p l a t e _ i d  
 	 , 	 o . o b j e c t _ i d  
 	 , 	 p . p r o p e r t y _ i d  
 f r o m   [ o r m _ m e t a ] . [ v a l u e s _ s t r i n g ]   a s   v  
 	 i n n e r   j o i n   [ o r m _ m e t a ] . [ o b j e c t s ]   a s   o  
 	 	 o n   v . o b j e c t _ i d   =   o . o b j e c t _ i d  
 	 i n n e r   j o i n   [ o r m _ m e t a ] . [ p r o p e r t i e s ]   a s   p  
 	 	 o n   v . p r o p e r t y _ i d   =   p . p r o p e r t y _ i d  
 	 i n n e r   j o i n   [ o r m _ m e t a ] . [ t e m p l a t e s ]   a s   t  
 	 	 o n   p . t e m p l a t e _ i d   =   t . t e m p l a t e _ i d  
 w h e r e   p . d a t a t y p e _ i d   =   1  
 o r d e r   b y   t . t e m p l a t e _ i d ,   o . n a m e ,   p . n a m e 
