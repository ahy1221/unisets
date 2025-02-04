
# Setup ----

sets_list <- list(
    set1 = c("A", "B"),
    set2 = c("B", "C", "D"),
    set3 = c("E")
)

# prepare named vectors to check that names are dropped by the constructor
elements_unlist <- unlist(sets_list)
sets_unlist <- rep(names(sets_list), lengths(sets_list))
names(sets_unlist) <- paste0("x", seq_along(sets_unlist))

relations <- DataFrame(
    element = elements_unlist,
    set     = sets_unlist,
    extra1  = rep(c("ABC", "DEF"), c(3L, 3L)),
    extra2  = seq(0, 1, length.out = 6L)
)

# BaseSets() ----

test_that("BaseSets constructor produces valid objects", {

    out <- BaseSets(relations)

    expect_s4_class(out, "BaseSets")

})

test_that("BaseSets validity method identifies issues", {

    # Invalid colnames(object@relations)
    map0 <- relations
    colnames(map0) <- c("A", "B")
    expect_error(
        BaseSets(relations=map0),
        "colnames(relations) must include c(\"element\", \"set\")",
        fixed=TRUE
    )

    # Mismatch between elements and elementData
    expect_error(
        BaseSets(relations, elementData=IdVector("Z")),
        "relations$element missing from ids(elementData)",
        fixed=TRUE
    )

    expect_error(
        BaseSets(relations, setData=IdVector("set999")),
        "relations$set missing from ids(setData)",
        fixed=TRUE
    )

    expect_error(
        BaseSets(relations, elementData=IdVector(relations$element)),
        "duplicated values in ids(elementData(object))",
        fixed=TRUE
    )

    expect_error(
        BaseSets(relations, setData=IdVector(relations$set)),
        "duplicated values in ids(setData(object))",
        fixed=TRUE
    )

    # Provide metadata columns without rownames set
    relations0 <- DataFrame(element="element1", set="set1")
    elementData=IdVector("element1")
    mcols(elementData) <- DataFrame(field="elementValue")
    setData=IdVector("set1")
    mcols(setData) <- DataFrame(field="setValue")

    # Check that rownames(mcols(x)) is not NULL (using the default use.names=TRUE)
    # while the actual DataFrame does not store rownames
    out <- BaseSets(relations0, elementData, setData)
    expect_true(!is.null(rownames(mcols(elementData(out)))))
    expect_null(rownames(out@elementData@elementMetadata))
    expect_true(!is.null(rownames(mcols(setData(out)))))
    expect_null(rownames(out@setData@elementMetadata))

})

# relations() ----

test_that("relations(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- relations(bs)
    expect_s4_class(out, "Hits")

})

# length() ----

test_that("length(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- length(bs)
    expect_identical(out, 6L)

})

# elements() ----

test_that("elements(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- elements(bs)
    expect_identical(out, bs@elementData[bs@relations@from])

})

# nElements() ----

test_that("nElements(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- nElements(bs)
    expect_identical(out, 5L)

})

# sets() ----

test_that("elements(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- sets(bs)
    expect_identical(out, bs@setData[bs@relations@to])

})

# nSets() ----

test_that("nSets(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- nSets(bs)
    expect_identical(out, 3L)

})

# elementData() ----

test_that("ids(elementData(BaseSets)) works", {

    bs <- BaseSets(relations)

    out <- elementData(bs)
    expect_s4_class(out, "IdVector")

    out <- ids(elementData(bs))
    expect_identical(out, c("A", "B", "C", "D", "E"))

})

# elementData<-() ----

test_that("elementData(BaseSets) <- value works", {

    bs <- BaseSets(relations)

    ids(elementData(bs)) <- tail(LETTERS, nElements(bs))

    expect_identical(ids(elementData(bs)), tail(LETTERS, nElements(bs)))

})

# setData() ----

test_that("setData(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- setData(bs)
    expect_s4_class(out, "IdVector")

    out <- ids(setData(bs))
    expect_identical(out, c("set1", "set2", "set3"))

})

# setData<-() ----

test_that("setData(BaseSets) <- value works", {

    bs <- BaseSets(relations)

    ids(setData(bs)) <- paste0("geneset", seq_len(nSets(bs)))

    expect_identical(ids(setData(bs)), paste0("geneset", seq_len(nSets(bs))))

})

# subset() ----

test_that("subset(BaseSets) works with default drop=TRUE", {

    bs <- BaseSets(relations)

    out <- subset(bs, set == "set1") # default is drop=TRUE

    expect_true(all(ids(setData(out)) == "set1"))
    expect_identical(length(setData(out)), 1L)

    out <- subset.BaseSets(bs, set == "set1") # default is drop=TRUE

    expect_true(all(ids(setData(out)) == "set1"))
    expect_identical(length(setData(out)), 1L)

    out <- bs[1:3] # default is drop=TRUE
    expect_identical(length(out), 3L)

})

test_that("subset(BaseSets) works with drop=FALSE", {

    bs <- BaseSets(relations)

    out <- subset(bs, set == "set1", drop=FALSE) # default is drop=TRUE

    expect_true(all(ids(sets(out)) == "set1"))
    expect_identical(ids(setData(out)), ids(setData(bs)))

    out <- subset.BaseSets(bs, set == "set1", drop=FALSE) # default is drop=TRUE

    expect_true(all(ids(sets(out)) == "set1"))
    expect_identical(ids(setData(out)), ids(setData(bs)))

    out <- bs[1:3, drop=FALSE] # default is drop=TRUE
    expect_identical(length(out), 3L)
    expect_identical(ids(setData(out)), ids(setData(bs)))

})

# c() ----

test_that("c(BaseSets) works", {

    bs1 <- bs2 <- bs3 <- BaseSets(relations)

    out <- c(bs1, bs2, bs3)

    # relations are concatenated
    expect_length(out, length(bs1) + length(bs2) + length(bs3))
    expect_identical(
        as.data.frame(out),
        rbind(as.data.frame(bs1), as.data.frame(bs2), as.data.frame(bs3))
    )
    # elements and sets are combined into their union
    expect_length(
        elementData(out),
        length(unique(c(ids(elementData(bs1)), ids(elementData(bs2)), ids(elementData(bs3)))))
    )
    expect_length(
        setData(out),
        length(unique(c(ids(setData(bs1)), ids(setData(bs2)), ids(setData(bs3)))))
    )

    out <- c.BaseSets(bs1, bs2, bs3)

    # relations are concatenated
    expect_length(out, length(bs1) + length(bs2) + length(bs3))
    expect_identical(
        as.data.frame(out),
        rbind(as.data.frame(bs1), as.data.frame(bs2), as.data.frame(bs3))
    )
    # elements and sets are combined into their union
    expect_length(
        elementData(out),
        length(unique(c(ids(elementData(bs1)), ids(elementData(bs2)), ids(elementData(bs3)))))
    )
    expect_length(
        setData(out),
        length(unique(c(ids(setData(bs1)), ids(setData(bs2)), ids(setData(bs3)))))
    )

})

# duplicated() ----

test_that("duplicated(BaseSets) works", {

    bs1 <- bs2 <- BaseSets(relations)

    # bs2 is an exact duplicate of bs1
    out <- duplicated(c(bs1, bs2))
    expect_identical(out, rep(c(FALSE, TRUE), c(length(bs1), length(bs2))))

    # change the metadata of the relations in bs2; creating _different_ relations
    mcols(relations(bs2)) <- mcols(relations(bs2))[rev(seq_along(bs2)), ]

    out <- duplicated(c(bs1, bs2))
    expect_identical(out, rep(c(FALSE, FALSE), c(length(bs1), length(bs2))))
})

# unique() ----

test_that("unique(BaseSets) works", {

    bs1 <- bs2 <- bs3 <- BaseSets(relations)

    bs <- c(bs1, bs2, bs3)

    out <- unique(bs)
    expect_length(out, length(bs1))
    expect_identical(out, bs1)
})

# union() ----

test_that("union(BaseSets) works", {

    bs1 <- bs2 <- BaseSets(relations)

    ids(elementData(bs2))[1] <- "new"

    out <- union(bs1, bs2)

    expect_identical(
        as.data.frame(out),
        unique(rbind(as.data.frame(bs1), as.data.frame(bs2)))
    )
    expect_identical(
        ids(elementData(out)),
        unique(c(ids(elementData(bs1)), ids(elementData(bs2))))
    )
    expect_identical(
        ids(setData(out)),
        unique(c(ids(setData(bs1)), ids(setData(bs2))))
    )

    out <- union.BaseSets(bs1, bs2)

    expect_identical(
        as.data.frame(out),
        unique(rbind(as.data.frame(bs1), as.data.frame(bs2)))
    )
    expect_identical(
        ids(elementData(out)),
        unique(c(ids(elementData(bs1)), ids(elementData(bs2))))
    )
    expect_identical(
        ids(setData(out)),
        unique(c(ids(setData(bs1)), ids(setData(bs2))))
    )
})

# show() ----

test_that("show(BaseSets) works", {

    # Small objects fully displayed
    bs <- BaseSets(relations)

    out <- show(bs)
    expect_identical(colnames(out), c("element", "set", "relationData", "elementData", "setData"))
    expect_identical(nrow(out), length(bs)+1L)

    # Large objects partially displayed
    bs <- BaseSets(relations=DataFrame(element=letters, set=LETTERS))

    out <- show(bs)
    expect_identical(colnames(out), c("element", "set", "relationData", "elementData", "setData"))
    expect_identical(nrow(out), unisets:::get_showHeadLines() + unisets:::get_showTailLines() + 2L)

})

# as.DataFrame() ----

test_that("as(BaseSets, \"DataFrame\") works", {

    bs <- BaseSets(relations)

    out <- as(bs, "DataFrame")
    expect_s4_class(out, "DataFrame")
    expect_identical(colnames(out), c("element", "set", "relationData", "elementData", "setData"))
    expect_identical(nrow(out), nrow(relations))

    out <- as.DataFrame.BaseSets(bs)
    expect_s4_class(out, "DataFrame")
    expect_identical(colnames(out), c("element", "set", "relationData", "elementData", "setData"))
    expect_identical(nrow(out), nrow(relations))

})

# as.data.frame() ----

test_that("as(BaseSets, \"data.frame\") works", {

    bs <- BaseSets(relations)

    out <- as(bs, "data.frame")
    expect_identical(colnames(out), c("element", "set", "extra1", "extra2"))
    expect_identical(dim(out), dim(relations))

    out <- as.data.frame.BaseSets(bs)
    expect_identical(colnames(out), c("element", "set", "extra1", "extra2"))
    expect_identical(dim(out), dim(relations))

})

# as.list() ----

test_that("as(BaseSets, \"list\") works", {

    bs <- BaseSets(relations)

    out <- as(bs, "list")
    expect_identical(lengths(out), c(set1 = 2L, set2 = 3L, set3 = 1L))
    out <- as.list(bs)
    expect_identical(lengths(out), c(set1 = 2L, set2 = 3L, set3 = 1L))

})

# as.matrix() ----

test_that("as(BaseSets, \"matrix\") works", {

    bs <- BaseSets(relations)

    expected.dim <- c(nElements(bs), nSets(bs))

    out <- as(bs, "matrix")
    expect_type(out, "logical")
    expect_identical(dim(out), expected.dim)

    out <- as.matrix(bs)
    expect_type(out, "logical")
    expect_identical(dim(out), expected.dim)

})

# as(list, "BaseSets") ----

test_that("as(list, \"BaseSets\") works", {

    bl <- list(set1=c("A", "B"), set2=c("B", "C"))

    out <- as(bl, "BaseSets")
    expect_s4_class(out, "BaseSets")
    expect_identical(length(out@relations), 4L)

    out <- as.BaseSets.list(bl, "BaseSets")
    expect_s4_class(out, "BaseSets")
    expect_identical(length(out@relations), 4L)

})

# as(matrix, "BaseSets") ----

test_that("as(matrix, \"BaseSets\") works", {

    nGenes <- 3
    nSets <- 2
    bm <- matrix(
        rep(c(TRUE, FALSE), nGenes),
        nrow=nGenes, ncol=nSets,
        dimnames=list(
            gene = paste0("gene", seq_len(nGenes)),
            set  = paste0("set", seq_len(nSets))
            )
        )

    out <- as(bm, "BaseSets")
    expect_s4_class(out, "BaseSets")
    expect_identical(length(out@relations), 3L) # 3 TRUE values above

    out <- as.BaseSets.matrix(bm, "BaseSets")
    expect_s4_class(out, "BaseSets")
    expect_identical(length(out@relations), 3L) # 3 TRUE values above

})

# setLengths() ----

test_that("setLengths(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- setLengths(bs)
    expect_identical(out, c(set1 = 2L, set2 = 3L, set3 = 1L))

})

# elementLengths() ----

test_that("elementLengths(BaseSets) works", {

    bs <- BaseSets(relations)

    out <- elementLengths(bs)
    expect_identical(out, c(A = 1L, B = 2L, C = 1L, D = 1L, E = 1L))

})

