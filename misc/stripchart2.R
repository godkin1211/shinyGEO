################################################################################
# generates dotplot evaluating differential expression for expression 
# vector 'x' and group labels 'y'. The 'GroupNames' are levels of 'y' in 
# presentation order, and 'group.names' are optional names for these levels 
################################################################################
stripchart2 <- function(x,y, GroupNames, group.names = NULL, col = NULL, 
                        main = "",  ...) {
  
  if (is.null(GroupNames)) return(NULL)
  
  keep = y%in%GroupNames
  x = x[keep]; y = y[keep] 
  s = split(x,y)
  num.groups = sum(sapply(s, function(x)!all(is.na(x)))) 
  stats = !(all(is.na(x) | length(s) == 0 | num.groups < 2))
  
  if (is.null(group.names)) group.names = GroupNames 
  
  if (is.null(col)) col = 1:length(s)
  add = NULL
  
  
  if (stats & length(s) == 2) {
    m = lapply(s,mean, na.rm=TRUE)
    
    fc = 2**(m[[GroupNames[2]]] - m[[GroupNames[1]]])
    #if (group.names[1] > group.names[2]) {
    #	fc = 1/fc
    #}
    
    fc = round(fc, 2)
    
    count.na <-function(x) sum(!is.na(x))
    n = sapply(s, count.na)
    
    if (min(n) > 1) {  
      t = t.test(s[[1]], s[[2]])
      p = round(t$p.value, 3)   
      if (p < 0.001) {
        p = "(P < 0.001)"
      } else {
        p = paste0("(P = ", p, ")")
      }
      add = paste("\nFC = ", fc, p, collapse = "")
    }
  } else if (stats) {
    l = lm(x~y); l = summary(l)
    if (any(l$df == 0)) {
      add = "\nP = NA"
    } else {
      p = 1-pf(l$fstatistic[1], l$fstatistic[2], l$fstatistic[3])
      p = round(p, 3)
      if (p < 0.001) {
        add = "\nP < 0.001"
      } else {
        add = paste0("\nP = ", p)
      }
    }
  } 
  
  if (is.null(main)) {
    main = "" 
  } else {
    main = paste(main, add)
  }
  
  m = melt(s, na.rm=FALSE)
  
  # re-order levels based on input order according to GroupNames 
  # this must be done here, as 'melt' reorders alphabetically	
  f <-function(x,l) {
    w = which(l%in%x)
    if (length(w) == 0) return(NA)
    w
  } 
  m$L1 = reorder(m$L1, sapply(m$L1,f,GroupNames))
  
  s2 = split(m$value, m$L1)
  n.groups = sapply(s2, function(x)sum(!is.na(x))) 
  n.groups = paste0("(n=", n.groups, ")")
  group.names = paste0(group.names, "\n", n.groups) 
  
  mean.no.na <<- function(x) mean(x,na.rm=TRUE)
  
  no.obs = FALSE
  if (all(is.na(m$value))) {
    no.obs = TRUE
    m$value[1] = 0
  }
  
  stripchart3 <- ggplot(m, aes(x = as.factor(L1), y = value, color=L1)) 
  stripchart3 <- stripchart3 + 
           labs(title = main, y = "log2 expression", x="") +
           theme(legend.position="none", 
                 axis.text.x = element_text(face = "bold", color = "black")) +
           scale_x_discrete(labels=group.names)
  if (!no.obs) {
      stripchart3 <- stripchart3 + 
           geom_point(position = position_jitter(h=0,w=NULL), aes(colour = L1), na.rm = TRUE) + 
           scale_colour_manual(values = col) +
           geom_errorbar(stat = "summary", fun.y = "mean.no.na", width=0.8,
                         aes(ymax=..y..,ymin=..y..))
  } 
  return(stripchart3)
}



